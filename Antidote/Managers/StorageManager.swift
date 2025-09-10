import Foundation
import FamilyControls

class StorageManager {
    static let shared = StorageManager()
    
    private init() {}
    
    private let appGroupIdentifier = "group.app.theantidote.theantidote"
    
    func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(selection) {
            UserDefaults(suiteName: appGroupIdentifier)?.set(encoded, forKey: "selectedApps")
        }
    }
    
    func loadFamilyActivitySelection() -> FamilyActivitySelection {
        if let data = UserDefaults(suiteName: appGroupIdentifier)?.data(forKey: "selectedApps") {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode(FamilyActivitySelection.self, from: data) {
                return loaded
            }
        }
        return FamilyActivitySelection()
    }
    
    func saveChallengeState(_ state: ChallengeState) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(state) {
            UserDefaults(suiteName: appGroupIdentifier)?.set(encoded, forKey: "challengeState")
        }
    }
    
    func loadChallengeState() -> ChallengeState {
        if let data = UserDefaults(suiteName: appGroupIdentifier)?.data(forKey: "challengeState") {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode(ChallengeState.self, from: data) {
                return loaded
            }
        }
        return ChallengeState()
    }
    
    func clearAllData() {
        UserDefaults(suiteName: appGroupIdentifier)?.removeObject(forKey: "selectedApps")
        UserDefaults(suiteName: appGroupIdentifier)?.removeObject(forKey: "challengeState")
        UserDefaults(suiteName: appGroupIdentifier)?.removeObject(forKey: "appSettings")
    }
}