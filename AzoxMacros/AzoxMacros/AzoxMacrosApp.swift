import SwiftUI
import Combine
import AppKit
import KeyboardShortcuts

@main
struct AzoxMacrosApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Azox Macros", systemImage: "keyboard") {
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
    static let toggleLeft = Self("toggleLeft", default: .init(.k, modifiers: [.command]))
    static let toggleRight = Self("toggleRight", default: .init(.l, modifiers: [.command]))
    static let toggleBoth = Self("toggleBoth", default: .init(.semicolon, modifiers: [.command]))
    static let toggleInputBlock = Self("toggleInputBlock", default: .init(.rightBracket, modifiers: [.command]))
    static let quitApp = Self("quitApp", default: .init(.escape, modifiers: [.command]))
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
        KeyboardShortcuts.onKeyUp(for: .toggleInputBlock) {
            InputBlocker.shared.toggle()
        }
        KeyboardShortcuts.onKeyUp(for: .quitApp) {
            NSApp.terminate(nil)
        }
    }
}
