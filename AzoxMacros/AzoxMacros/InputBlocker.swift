import Foundation
import Combine
import AppKit
import Carbon.HIToolbox

private let kUnblockKeyCodes: Set<Int> = [
    Int(kVK_ANSI_RightBracket),  // ]
    Int(kVK_ANSI_Semicolon),    // ;
    Int(kVK_ANSI_K),            // K
    Int(kVK_ANSI_L),            // L
    Int(kVK_ANSI_J),            // J
    Int(kVK_ANSI_Slash),        // /
    Int(kVK_ANSI_M),            // M
    Int(kVK_ANSI_N),            // N
    Int(kVK_ANSI_P),            // P
    Int(kVK_ANSI_Q),            // Q
    Int(kVK_Escape),            // Escape
]

final class InputBlocker: ObservableObject {
    static let shared = InputBlocker()
    
    @Published private(set) var isBlocked: Bool = false
    @Published var failSafeEnabled: Bool = true {
        didSet { UserDefaults.standard.set(failSafeEnabled, forKey: "inputBlockFailSafeEnabled") }
    }
    @Published var failSafeSeconds: Double = 10.0 {
        didSet { UserDefaults.standard.set(failSafeSeconds, forKey: "inputBlockFailSafeSeconds") }
    }
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var failSafeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var localMonitor: Any?
    
    private init() {
        failSafeEnabled = UserDefaults.standard.object(forKey: "inputBlockFailSafeEnabled") as? Bool ?? true
        failSafeSeconds = UserDefaults.standard.object(forKey: "inputBlockFailSafeSeconds") as? Double ?? 10.0
        
        NotificationCenter.default.publisher(for: .inputBlockAutoDisabled)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.isBlocked = false
            }
            .store(in: &cancellables)
    }
    
    func setBlocked(_ blocked: Bool) {
        if blocked {
            enable()
        } else {
            disable()
        }
    }
    
    func toggle() {
        if isBlocked {
            disable()
        } else {
            enable()
        }
    }
    
    private func enable() {
        guard !isBlocked else { return }
        
        var eventMask: CGEventMask = 0
        eventMask |= (1 << CGEventType.keyDown.rawValue)
        eventMask |= (1 << CGEventType.keyUp.rawValue)
        eventMask |= (1 << CGEventType.flagsChanged.rawValue)
        eventMask |= (1 << CGEventType.leftMouseDown.rawValue)
        eventMask |= (1 << CGEventType.leftMouseUp.rawValue)
        eventMask |= (1 << CGEventType.rightMouseDown.rawValue)
        eventMask |= (1 << CGEventType.rightMouseUp.rawValue)
        eventMask |= (1 << CGEventType.otherMouseDown.rawValue)
        eventMask |= (1 << CGEventType.otherMouseUp.rawValue)
        eventMask |= (1 << CGEventType.mouseMoved.rawValue)
        eventMask |= (1 << CGEventType.leftMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.rightMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.otherMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.scrollWheel.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                return nil
            }
            
            if type == .keyDown || type == .keyUp {
                let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags
                
                let isCommand = flags.contains(.maskCommand)
                
                if isCommand && kUnblockKeyCodes.contains(keyCode) {
                    return Unmanaged.passRetained(event)
                }
            }
            
            return nil
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: nil
        ) else {
            print("InputBlocker: Failed to create event tap - need Accessibility permission")
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        eventTap = tap
        isBlocked = true
        
        NSEvent.addLocalMonitorForEvents(matching: .swipe) { _ in
            return nil
        }
        
        if failSafeEnabled {
            startFailSafeTimer()
        }
        
        print("InputBlocker: Input devices blocked (fail-safe: \(failSafeEnabled ? "ON (\(Int(failSafeSeconds))s)" : "OFF")")
    }
    
    private func disable() {
        failSafeTimer?.invalidate()
        failSafeTimer = nil
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        
        eventTap = nil
        runLoopSource = nil
        isBlocked = false
        print("InputBlocker: Input devices unblocked")
    }
    
    private func startFailSafeTimer() {
        failSafeTimer?.invalidate()
        failSafeTimer = Timer.scheduledTimer(withTimeInterval: failSafeSeconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("InputBlocker: Fail-safe triggered - auto-disabling input block")
                self?.disable()
                NotificationCenter.default.post(name: .inputBlockAutoDisabled, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let inputBlockAutoDisabled = Notification.Name("inputBlockAutoDisabled")
}
