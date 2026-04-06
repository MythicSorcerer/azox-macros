import SwiftUI
import AppKit
import KeyboardShortcuts

@main
struct AzoxClickerApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var engine = ClickEngine()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        KeyboardShortcuts.onKeyUp(for: .toggleLeft) { [weak engine] in
            engine?.toggle(button: .left)
        }
        KeyboardShortcuts.onKeyUp(for: .toggleRight) { [weak engine] in
            engine?.toggle(button: .right)
        }
        KeyboardShortcuts.onKeyUp(for: .toggleBoth) { [weak engine] in
            engine?.toggle(button: .both)
        }
    }

    var body: some Scene {
        MenuBarExtra("Azox Clicker", systemImage: "cursorarrow.click") {
            MenuView()
                .environmentObject(settings)
                .environmentObject(engine)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(engine)
        }
    }
}

extension KeyboardShortcuts.Name {
    static let toggleLeft = Self("toggleLeft")
    static let toggleRight = Self("toggleRight")
    static let toggleBoth = Self("toggleBoth")
}
