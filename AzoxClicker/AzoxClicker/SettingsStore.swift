import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var config: ClickConfiguration
    private var cancellables = Set<AnyCancellable>()

    private static let storageKey = "AzoxClickerConfig"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(ClickConfiguration.self, from: data) {
            config = decoded
        } else {
            config = ClickConfiguration()
        }

        $config
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { value in
                if let data = try? JSONEncoder().encode(value) {
                    UserDefaults.standard.set(data, forKey: Self.storageKey)
                }
            }
            .store(in: &cancellables)
    }
}
