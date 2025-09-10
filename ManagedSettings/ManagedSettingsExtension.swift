
import ManagedSettings
import SwiftUI
import Foundation
import FamilyControls

// By creating a Codable wrapper around FamilyActivitySelection, we can save it to UserDefaults.
struct CodableFamilyActivitySelection: Codable {
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
    var webDomainTokens: Set<WebDomainToken>

    init(selection: FamilyActivitySelection) {
        self.applicationTokens = selection.applicationTokens
        self.categoryTokens = selection.categoryTokens
        self.webDomainTokens = selection.webDomainTokens
    }

    func toFamilyActivitySelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = self.applicationTokens
        selection.categoryTokens = self.categoryTokens
        selection.webDomainTokens = self.webDomainTokens
        return selection
    }
}

struct AppSettings: Codable {
    var dailyLimitMinutes: Int = 45
    var challengeType: ChallengeType = .stroop
    var isFirstLaunch: Bool = true
    var hasCompletedOnboarding: Bool = false
    var lastResetDate: Date = Date()
    var passesUsedToday: Int = 0
    var lastFailedChallengeDate: Date? = nil
    var failedAttempts: Int = 0
    var bypassEndTime: Date? = nil
    
    // Store the Codable wrapper instead of the selection itself.
    private var codableSelectedApps: CodableFamilyActivitySelection?
    
    // Provide a computed property to access the real FamilyActivitySelection.
    var selectedApps: FamilyActivitySelection {
        get { codableSelectedApps?.toFamilyActivitySelection() ?? FamilyActivitySelection() }
        set { codableSelectedApps = CodableFamilyActivitySelection(selection: newValue) }
    }
    
    static let appGroupIdentifier = "group.app.theantidote.theantidote"
    
    init() {}
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            // Try app group first, fallback to standard UserDefaults
            if let appGroupDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
                appGroupDefaults.set(encoded, forKey: "appSettings")
            } else {
                UserDefaults.standard.set(encoded, forKey: "appSettings")
            }
        }
    }
    
    static func load() -> AppSettings {
        // Try app group first, fallback to standard UserDefaults
        var data: Data?
        
        if let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            data = appGroupDefaults.data(forKey: "appSettings")
        }
        
        if data == nil {
            data = UserDefaults.standard.data(forKey: "appSettings")
        }
        
        if let data = data {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode(AppSettings.self, from: data) {
                return loaded
            }
        }
        
        return AppSettings()
    }
}

enum ChallengeType: String, CaseIterable, Codable {
    case stroop = "Stroop Test"
    case math = "Math Problems"
    case trivia = "Trivia Questions"
    case breath = "Breathing Exercise"
}

// By conforming to the ManagedSettingsStoreDelegate protocol, you can customize the shield configuration.
class ManagedSettingsExtension: ManagedSettingsStoreDelegate {
    override init() {
        super.init()
    }
    
    // This delegate method is called when the system needs to display the shield.
    // You can customize the appearance and actions of the shield here.
    override func configuration(for store: ManagedSettingsStore) -> ShieldConfiguration {
        
        // Load the latest settings from your app's shared storage.
        let settings = AppSettings.load()
        
        return ShieldConfiguration(
            backgroundColor: .systemBackground,
            icon: ShieldIcon(systemName: "brain.fill"),
            title: ShieldLabel(text: "Limit Reached", color: .label),
            subtitle: ShieldLabel(text: "Complete a challenge to continue.", color: .secondaryLabel),
            primaryButtonLabel: ShieldLabel(text: "Take Challenge"),
            // The primary button action should deep link back to your app.
            primaryButtonAction: .url(URL(string: "antidote://challenge")!)
        )
    }
}
