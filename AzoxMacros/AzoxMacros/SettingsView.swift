import SwiftUI
import KeyboardShortcuts
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @ObservedObject private var inputBlocker = InputBlocker.shared

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Changes save automatically")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done Editing") {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            }
            .padding(.horizontal, 4)

            Form {
                Section("Input Block Shortcut") {
                    ShortcutRow(title: "Toggle Input Block", name: .toggleInputBlock)
                    Text("Use this shortcut to quickly enable/disable input blocking.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Input Block Safety") {
                    Toggle("Auto-Disable Input Block", isOn: $inputBlocker.failSafeEnabled)
                    
                    if inputBlocker.failSafeEnabled {
                        HStack {
                            Text("Disable after (seconds):")
                            Spacer()
                            TextField("10", value: $inputBlocker.failSafeSeconds, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Stepper("", value: $inputBlocker.failSafeSeconds, in: 1...300, step: 1)
                                .labelsHidden()
                        }
                        Text("Input blocking will automatically turn off after this time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Touch ID Lock") {
                    Toggle("Disable Touch ID Lock", isOn: $settings.touchIdLockDisabled)
                    if !TouchIDManager.shared.isTouchIDAvailable() {
                        Text("Touch ID is not available on this device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("When enabled, Touch ID will not lock your computer.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Shortcuts") {
                    ShortcutRow(title: "Toggle Left Clicker", name: .toggleLeft)
                    ShortcutRow(title: "Toggle Right Clicker", name: .toggleRight)
                    ShortcutRow(title: "Toggle Both Clicker", name: .toggleBoth)
                    ShortcutRow(title: "Quit App (Fail-safe)", name: .quitApp)
                }

                Section("Click Speed") {
                    Picker("Rate Mode", selection: $settings.config.rateMode) {
                        ForEach(RateMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    RateModeEditor(config: $settings.config)

                    WarningRow(maxCps: settings.config.maxCPS())
                }

                Section("Auto Stop") {
                    Toggle("Bypass 5s Safety Limit", isOn: $settings.config.bypassSafetyTimeLimit)
                    if !settings.config.bypassSafetyTimeLimit {
                        Text("Safety limit is active: clicker force-stops after 5 seconds.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Stop Mode", selection: $settings.config.stopMode) {
                        ForEach(StopMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    StopModeEditor(config: $settings.config)
                }

                Section("Quick Tips") {
                    Text("Use fixed CPS + stop after time for the classic CPS + end time workflow.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Input block has auto-disable by default to prevent getting locked out.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .textFieldStyle(.roundedBorder)
            .onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .padding(16)
        .frame(minWidth: 620, minHeight: 750)
    }
}

private struct ShortcutRow: View {
    let title: String
    let name: KeyboardShortcuts.Name

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}

private struct WarningRow: View {
    let maxCps: Double

    var body: some View {
        HStack(spacing: 8) {
            if maxCps > 100 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .help("Warning: Click speeds above 100 CPS may cause apps to freeze.")
                Text("High click speed detected")
                    .foregroundStyle(.orange)
            } else {
                Text("Click speed OK")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RateModeEditor: View {
    @Binding var config: ClickConfiguration

    var body: some View {
        switch config.rateMode {
        case .fixedCPS:
            HStack {
                Text("CPS")
                Spacer()
                TextField("50", value: $config.cps, format: .number)
                    .frame(width: 120)
            }
        case .fixedInterval:
            HStack {
                Text("Interval")
                Spacer()
                TextField("50", value: $config.intervalValue, format: .number)
                    .frame(width: 120)
                Picker("", selection: $config.intervalUnit) {
                    ForEach(TimeUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .labelsHidden()
            }
        case .clicksPerDuration:
            HStack {
                Text("Clicks")
                TextField("10", value: $config.clicksPerDuration, format: .number)
                    .frame(width: 120)
                Text("per")
                TextField("1", value: $config.durationValue, format: .number)
                    .frame(width: 100)
                Picker("", selection: $config.durationUnit) {
                    ForEach(TimeUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .labelsHidden()
            }
        case .randomInterval:
            HStack {
                Text("Interval Min")
                TextField("20", value: $config.randomIntervalMin, format: .number)
                    .frame(width: 120)
                Text("Max")
                TextField("80", value: $config.randomIntervalMax, format: .number)
                    .frame(width: 120)
                Picker("", selection: $config.randomIntervalUnit) {
                    ForEach(TimeUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .labelsHidden()
            }
        case .randomCPS:
            HStack {
                Text("Min CPS")
                TextField("10", value: $config.randomCpsMin, format: .number)
                    .frame(width: 120)
                Text("Max CPS")
                TextField("40", value: $config.randomCpsMax, format: .number)
                    .frame(width: 120)
            }
        }
    }
}

private struct StopModeEditor: View {
    @Binding var config: ClickConfiguration

    var body: some View {
        switch config.stopMode {
        case .none:
            Text("No auto-stop configured.")
                .foregroundStyle(.secondary)
        case .afterTime:
            HStack {
                Text("Time")
                Spacer()
                TextField("10", value: $config.stopTimeValue, format: .number)
                    .frame(width: 120)
                Picker("", selection: $config.stopTimeUnit) {
                    ForEach(TimeUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .labelsHidden()
            }
        case .afterClicks:
            HStack {
                Text("Clicks")
                Spacer()
                TextField("1000", value: $config.stopClicks, format: .number)
                    .frame(width: 120)
            }
        case .randomTimeRange:
            HStack {
                Text("Time Min")
                TextField("5", value: $config.randomTimeMin, format: .number)
                    .frame(width: 120)
                Text("Max")
                TextField("15", value: $config.randomTimeMax, format: .number)
                    .frame(width: 120)
                Picker("", selection: $config.randomTimeUnit) {
                    ForEach(TimeUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .labelsHidden()
            }
        case .randomClickRange:
            HStack {
                Text("Click Min")
                TextField("500", value: $config.randomClicksMin, format: .number)
                    .frame(width: 120)
                Text("Max")
                TextField("1500", value: $config.randomClicksMax, format: .number)
                    .frame(width: 120)
            }
        }
    }
}
