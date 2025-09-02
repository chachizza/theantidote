import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

enum ChallengeType: String, CaseIterable, Codable {
    case stroop = "Stroop Test"
    case math = "Math Problems"
    case trivia = "Trivia Questions"
    case breath = "Breathing Exercise"
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
    var selectedApps: FamilyActivitySelection = FamilyActivitySelection()
    
    static let shared = AppSettings()
    
    private init() {}
    
    static let appGroupIdentifier = "group.com.yourcompany.antidote"
    
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
    
    mutating func resetDailyCounters() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            passesUsedToday = 0
            failedAttempts = 0
            lastResetDate = Date()
        }
    }
    
    mutating func canUsePass() -> Bool {
        resetDailyCounters()
        return passesUsedToday < 2
    }
    
    mutating func usePass() {
        passesUsedToday += 1
        save()
    }
}