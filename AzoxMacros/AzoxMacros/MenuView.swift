import SwiftUI
import AppKit
import KeyboardShortcuts

struct MenuView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var engine: ClickEngine
    @ObservedObject private var inputBlocker = InputBlocker.shared
    @Environment(\.openSettings) private var openSettingsAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !AccessibilityPermission.isTrusted() {
                PermissionBanner()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Status")
                    .font(.headline)
                Text(engine.isRunning ? "Running" : "Stopped")
                    .foregroundStyle(engine.isRunning ? .green : .secondary)
                if engine.isRunning, let button = engine.activeButton {
                    Text("Mode: \(button.label)")
                        .font(.caption)
                }
                Text("Clicks: \(engine.clicksCompleted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(settings.config.bypassSafetyTimeLimit ? "Safety: Bypassed" : "Safety: Auto-stop at 5s")
                    .font(.caption)
                    .foregroundStyle(settings.config.bypassSafetyTimeLimit ? .orange : .secondary)
            }

            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Features")
                    .font(.headline)
                HStack {
                    Image(systemName: settings.touchIdLockDisabled ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(settings.touchIdLockDisabled ? .green : .secondary)
                    Text("Touch ID Lock: \(settings.touchIdLockDisabled ? "Disabled" : "Enabled")")
                        .font(.caption)
                }
                HStack {
                    Image(systemName: inputBlocker.isBlocked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(inputBlocker.isBlocked ? .green : .secondary)
                    Button(action: {
                        inputBlocker.toggle()
                    }) {
                        Text("Input Block: \(inputBlocker.isBlocked ? "Active" : "Inactive")")
                            .font(.caption)
                            .foregroundStyle(inputBlocker.isBlocked ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if inputBlocker.isBlocked {
                InputBlockWarningBanner(failSafeEnabled: inputBlocker.failSafeEnabled, failSafeSeconds: inputBlocker.failSafeSeconds)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Clicker")
                    .font(.headline)
                Button(engine.isRunning ? "Stop" : "Start Left Clicker") {
                    if engine.isRunning {
                        engine.stop()
                    } else {
                        engine.start(button: .left, config: settings.config)
                    }
                }

                Button(engine.isRunning ? "Stop" : "Start Right Clicker") {
                    if engine.isRunning {
                        engine.stop()
                    } else {
                        engine.start(button: .right, config: settings.config)
                    }
                }

                Button(engine.isRunning ? "Stop" : "Start Both Clicker") {
                    if engine.isRunning {
                        engine.stop()
                    } else {
                        engine.start(button: .both, config: settings.config)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkeys")
                    .font(.headline)
                MenuShortcutRow(title: "Left", name: .toggleLeft)
                MenuShortcutRow(title: "Right", name: .toggleRight)
                MenuShortcutRow(title: "Both", name: .toggleBoth)
                MenuShortcutRow(title: "Input Block", name: .toggleInputBlock)
                Divider()
                MenuShortcutRow(title: "Quit (Fail-safe)", name: .quitApp)
            }

            Divider()

            Button("Open Settings") {
                openSettingsWindow()
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .onReceive(settings.$config) { newValue in
            engine.updateConfig(newValue)
        }
        .frame(width: 340)
    }

    private func openSettingsWindow() {
        openSettingsAction()
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            NSApp.activate(ignoringOtherApps: true)
            if let settingsWindow = NSApp.windows.first(where: {
                $0.title.localizedCaseInsensitiveContains("settings")
            }) {
                settingsWindow.makeKeyAndOrderFront(nil)
                settingsWindow.orderFrontRegardless()
            }
        }
    }
}

private struct MenuShortcutRow: View {
    let title: String
    let name: KeyboardShortcuts.Name

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}

private struct InputBlockWarningBanner: View {
    let failSafeEnabled: Bool
    let failSafeSeconds: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Input Blocked!")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            if failSafeEnabled {
                Text("Auto-disables in \(Int(failSafeSeconds))s. Press shortcut to unblock.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("No auto-disable. Press shortcut to unblock.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
    }
}

private struct PermissionBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Accessibility Permission Needed")
                .font(.headline)
            Text("Enable Accessibility for Azox Macros to send mouse events and block input.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Open Settings") {
                    AccessibilityPermission.openSystemSettings()
                }
                Button("Request") {
                    AccessibilityPermission.request()
                }
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
    }
}
