
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
            UserDefaults(suiteName: Self.appGroupIdentifier)?.set(encoded, forKey: "appSettings")
        }
    }
    
    static func load() -> AppSettings {
        if let data = UserDefaults(suiteName: appGroupIdentifier)?.data(forKey: "appSettings") {
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
