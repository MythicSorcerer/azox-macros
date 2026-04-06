import Foundation
import AppKit

@MainActor
final class ClickEngine: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var clicksCompleted: Int = 0
    @Published private(set) var activeButton: ClickButton? = nil

    private var task: Task<Void, Never>? = nil
    private var startTime: Date? = nil
    private var stopPlan: (maxClicks: Int?, maxTime: Double?) = (nil, nil)
    private var currentInterval: ClosedRange<Double> = 0.05...0.05
    private var configSnapshot = ClickConfiguration()

    func toggle(button: ClickButton) {
        if isRunning {
            stop()
        } else {
            start(button: button)
        }
    }

    func start(button: ClickButton, config: ClickConfiguration? = nil) {
        stop()

        let resolvedConfig = config ?? configSnapshot
        configSnapshot = resolvedConfig
        currentInterval = resolvedConfig.resolvedIntervalSeconds()
        stopPlan = resolvedConfig.resolvedStopPlan()
        isRunning = true
        clicksCompleted = 0
        activeButton = button
        startTime = Date()

        task = Task.detached { [weak self] in
            await self?.runLoop(button: button)
        }
    }

    func updateConfig(_ config: ClickConfiguration) {
        configSnapshot = config
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
        activeButton = nil
        startTime = nil
    }

    private func runLoop(button: ClickButton) async {
        while !Task.isCancelled {
            await postClick(button: button)

            await MainActor.run {
                clicksCompleted += 1
            }

            if shouldStop() {
                await MainActor.run {
                    stop()
                }
                break
            }

            let interval = Double.random(in: currentInterval)
            let nanoseconds = UInt64(max(0.0001, interval) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    }

    private func shouldStop() -> Bool {
        if let maxClicks = stopPlan.maxClicks, clicksCompleted >= maxClicks {
            return true
        }
        if let maxTime = stopPlan.maxTime, let start = startTime {
            return Date().timeIntervalSince(start) >= maxTime
        }
        return false
    }

    private func postClick(button: ClickButton) async {
        let location = NSEvent.mouseLocation
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let point = CGPoint(x: location.x, y: screenHeight - location.y)

        switch button {
        case .left:
            postMouse(type: .leftMouseDown, point: point, button: .left)
            postMouse(type: .leftMouseUp, point: point, button: .left)
        case .right:
            postMouse(type: .rightMouseDown, point: point, button: .right)
            postMouse(type: .rightMouseUp, point: point, button: .right)
        case .both:
            postMouse(type: .leftMouseDown, point: point, button: .left)
            postMouse(type: .leftMouseUp, point: point, button: .left)
            postMouse(type: .rightMouseDown, point: point, button: .right)
            postMouse(type: .rightMouseUp, point: point, button: .right)
        }
    }

    private func postMouse(type: CGEventType, point: CGPoint, button: CGMouseButton) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }
}
