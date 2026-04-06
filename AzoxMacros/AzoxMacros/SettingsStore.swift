import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var config: ClickConfiguration
    @Published var touchIdLockDisabled: Bool {
        didSet {
            TouchIDManager.shared.setDisabled(touchIdLockDisabled)
            saveSettings()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()

    private static let storageKey = "AzoxMacrosConfig"
    private static let touchIdKey = "touchIdLockDisabled"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(ClickConfiguration.self, from: data) {
            config = decoded
        } else {
            config = ClickConfiguration()
        }
        
        touchIdLockDisabled = UserDefaults.standard.bool(forKey: Self.touchIdKey)

        $config
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    UserDefaults.standard.set(data, forKey: Self.storageKey)
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(touchIdLockDisabled, forKey: Self.touchIdKey)
    }
}
