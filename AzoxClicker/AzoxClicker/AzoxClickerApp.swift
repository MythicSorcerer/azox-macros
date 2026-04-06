import SwiftUI
import Combine
import AppKit
import KeyboardShortcuts

@main
struct AzoxClickerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Azox Clicker", systemImage: "cursorarrow.click") {
            MenuView()
                .environmentObject(appState.settings)
                .environmentObject(appState.engine)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState.settings)
                .environmentObject(appState.engine)
        }
    }
}

extension KeyboardShortcuts.Name {
    static let toggleLeft = Self("toggleLeft")
    static let toggleRight = Self("toggleRight")
    static let toggleBoth = Self("toggleBoth")
}

@MainActor
final class AppState: ObservableObject {
    let settings = SettingsStore()
    let engine = ClickEngine()
    private var cancellables = Set<AnyCancellable>()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        engine.updateConfig(settings.config)

        settings.$config
            .sink { [weak engine] config in
                engine?.updateConfig(config)
            }
            .store(in: &cancellables)

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
}
