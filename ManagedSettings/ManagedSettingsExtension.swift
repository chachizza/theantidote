import ManagedSettings
import SwiftUI

class ManagedSettingsExtension: ManagedSettingsStoreDelegate {
    static let shared = ManagedSettingsExtension()
    
    private init() {}
    
    func configuration(for store: ManagedSettingsStore) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundColor: .systemBackground,
            icon: ShieldIcon(systemName: "shield.fill"),
            title: ShieldLabel(text: "Daily Limit Reached", color: .label),
            subtitle: ShieldLabel(text: "Complete a mindful challenge to unlock your apps", color: .secondaryLabel),
            primaryButtonLabel: ShieldLabel(text: "Open The Antidote", color: .systemBlue),
            primaryButtonAction: .customAction { _ in
                // Deep link to the app
                return URL(string: "antidote://challenge")!
            }
        )
    }
    
    func store(_ store: ManagedSettingsStore, didChangeStatus status: ManagedSettingsStore.Status) {
        switch status {
        case .active:
            print("Shield is active")
        case .inactive:
            print("Shield is inactive")
        @unknown default:
            print("Unknown status: \(status)")
        }
    }
    
    func setupShield() {
        let store = ManagedSettingsStore()
        store.delegate = self
        
        // Load shield configuration from app group
        if let data = UserDefaults(suiteName: "group.com.yourcompany.antidote")?.data(forKey: "shieldConfiguration") {
            let decoder = JSONDecoder()
            if let config = try? decoder.decode(ShieldConfig.self, from: data) {
                // Apply shield configuration
                store.shield.applications = config.applications
                store.shield.categories = config.categories
                
                // Set custom shield configuration
                store.shield.configuration = configuration(for: store)
            }
        }
    }
}

struct ShieldConfig: Codable {
    let applications: Set<ApplicationToken>
    let categories: Set<ActivityCategoryToken>
}

// Extension entry point
class ManagedSettingsExtension: ManagedSettingsStore {
    override init() {
        super.init()
        self.delegate = ManagedSettingsExtension.shared
        ManagedSettingsExtension.shared.setupShield()
    }
}

// Custom shield configuration
extension ShieldConfiguration {
    static func customShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundColor: UIColor.systemBackground,
            icon: ShieldIcon(systemName: "brain.fill"),
            title: ShieldLabel(text: "Mindful Moment", color: UIColor.label),
            subtitle: ShieldLabel(text: "Complete a challenge to unlock your apps", color: UIColor.secondaryLabel),
            primaryButtonLabel: ShieldLabel(text: "Take Challenge", color: UIColor.systemBlue),
            primaryButtonAction: .customAction { _ in
                return URL(string: "antidote://challenge")!
            }
        )
    }
}