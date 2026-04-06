import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var engine: ClickEngine

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
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
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

            Button("Open Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .onReceive(settings.$config) { newValue in
            engine.updateConfig(newValue)
        }
        .frame(width: 280)
    }
}

private struct PermissionBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Accessibility Permission Needed")
                .font(.headline)
            Text("Enable Accessibility for Azox Clicker to send mouse events.")
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
