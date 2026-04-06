import Foundation
import LocalAuthentication
import AppKit

final class TouchIDManager {
    static let shared = TouchIDManager()
    
    private init() {}
    
    func setDisabled(_ disabled: Bool) {
        if disabled {
            enable()
        } else {
            disable()
        }
    }
    
    private func enable() {
        let alert = NSAlert()
        alert.messageText = "Disable Touch ID Lock"
        alert.informativeText = "To disable Touch ID lock, please go to System Settings > Touch ID & Password and turn off 'Use Touch ID for purchases' and 'Use Touch ID for autofill'.\n\nWould you like to open System Settings?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?General_TouchID") {
                NSWorkspace.shared.open(url)
            }
        }
        
        print("TouchIDManager: User notified about Touch ID settings")
    }
    
    private func disable() {
        print("TouchIDManager: Touch ID lock re-enabled")
    }
    
    func isTouchIDAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}
