
import DeviceActivity
import ManagedSettings
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

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override init() {
        super.init()
        print("🔌 EXTENSION: DeviceActivityMonitorExtension initialized!")
        
        // Try to write a diagnostic file to confirm extension is loading
        let diagnosticMessage = "Extension initialized at \(Date())\n"
        if let data = diagnosticMessage.data(using: .utf8) {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let documentsPath = paths.first {
                let logFile = documentsPath.appendingPathComponent("extension_log.txt")
                try? data.write(to: logFile)
                print("🔌 EXTENSION: Diagnostic log written to \(logFile.path)")
            }
        }
        
        // Load settings to verify app group access works
        let settings = AppSettings.load()
        print("🔌 EXTENSION: Init - Daily limit: \(settings.dailyLimitMinutes) minutes")
        print("🔌 EXTENSION: Init - Selected apps: \(settings.selectedApps.applicationTokens.count)")
        print("🔌 EXTENSION: Init - Selected categories: \(settings.selectedApps.categoryTokens.count)")
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🚀 EXTENSION: DeviceActivity interval started for: \(activity)")
        
        let settings = AppSettings.load()
        print("🚀 EXTENSION: Loaded settings - Daily limit: \(settings.dailyLimitMinutes) minutes")
        print("🚀 EXTENSION: Selected apps count: \(settings.selectedApps.applicationTokens.count)")
        print("🚀 EXTENSION: Selected categories count: \(settings.selectedApps.categoryTokens.count)")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // When the interval (the day) ends, clear the shield completely.
        print("📅 EXTENSION: Day ended - clearing all shields for: \(activity)")
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        print("🔥 EXTENSION: EVENT TRIGGERED! \(event) for activity: \(activity)")
        print("🔥 EXTENSION: Current time: \(Date())")
        
        let settings = AppSettings.load()
        print("🔥 EXTENSION: Loaded settings in threshold event")
        
        // Check if a bypass is active. If so, do nothing.
        if let bypassEnd = settings.bypassEndTime, bypassEnd > Date() {
            print("🔥 EXTENSION: Bypass is active until \(bypassEnd). Not shielding apps.")
            return
        }
        
        // If the event is the time limit threshold, shield the selected apps and categories.
        let selection = settings.selectedApps
        
        print("🛡️ EXTENSION: Shielding triggered!")
        print("🛡️ EXTENSION: Applications to shield: \(selection.applicationTokens.count)")
        print("🛡️ EXTENSION: Categories to shield: \(selection.categoryTokens.count)")
        print("🛡️ EXTENSION: Web domains: \(selection.webDomainTokens.count)")
        
        // Shield individual applications
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            print("🛡️ EXTENSION: ✅ Applications shielded: \(selection.applicationTokens.count)")
        }
        
        // Shield app categories - this is the key fix!
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            print("🛡️ EXTENSION: ✅ Categories shielded: \(selection.categoryTokens.count)")
        }
        
        // Handle web domain restrictions if any are selected  
        if !selection.webDomainTokens.isEmpty {
            // Note: Web domains may need different handling
            print("🛡️ EXTENSION: ⚠️ Web domains selected but not yet supported: \(selection.webDomainTokens.count)")
        }
        
        print("🛡️ EXTENSION: ✅ Shield activation complete!")
        
        // Log current shield state
        print("🛡️ EXTENSION: Current shield state:")
        print("🛡️ EXTENSION:   - Applications shielded: \(store.shield.applications?.count ?? 0)")
        if let appCategories = store.shield.applicationCategories {
            switch appCategories {
            case .all:
                print("🛡️ EXTENSION:   - All app categories shielded")
            case .specific(let tokens, except: _):
                print("🛡️ EXTENSION:   - Specific app categories shielded: \(tokens.count)")
            case .none:
                print("🛡️ EXTENSION:   - No app categories shielded")
            @unknown default:
                print("🛡️ EXTENSION:   - Unknown app category shield type")
            }
        } else {
            print("🛡️ EXTENSION:   - No app categories shielded")
        }
    }
    
}
