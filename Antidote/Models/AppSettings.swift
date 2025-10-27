import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

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
    var selectionMetadata: [AppSelectionMetadata] = []
    
    // Store the Codable wrapper instead of the selection itself.
    private var codableSelectedApps: CodableFamilyActivitySelection?
    
    // Provide a computed property to access the real FamilyActivitySelection.
    var selectedApps: FamilyActivitySelection {
        get { codableSelectedApps?.toFamilyActivitySelection() ?? FamilyActivitySelection() }
        set {
            codableSelectedApps = CodableFamilyActivitySelection(selection: newValue)
            selectionMetadata = AppSettings.buildMetadata(for: newValue)
        }
    }
    
    static let appGroupIdentifier = "group.app.theantidote.theantidote"
    
    init() {}
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            // Try app group first, fallback to standard UserDefaults
            if let appGroupDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
                appGroupDefaults.set(encoded, forKey: "appSettings")
                print("Settings saved to app group")
            } else {
                UserDefaults.standard.set(encoded, forKey: "appSettings")
                print("Settings saved to standard UserDefaults (fallback)")
            }
        }
    }
    
    static func load() -> AppSettings {
        // Try app group first, fallback to standard UserDefaults
        var data: Data?
        
        if let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            data = appGroupDefaults.data(forKey: "appSettings")
            if data != nil {
                print("Settings loaded from app group")
            }
        }
        
        if data == nil {
            data = UserDefaults.standard.data(forKey: "appSettings")
            if data != nil {
                print("Settings loaded from standard UserDefaults (fallback)")
            }
        }
        
        if let data = data {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode(AppSettings.self, from: data) {
                return loaded
            }
        }
        
        print("Creating new AppSettings with defaults")
        return AppSettings()
    }
}

struct AppSelectionMetadata: Codable, Hashable, Identifiable {
    enum Kind: String, Codable {
        case app
        case category
        case domain
    }
    var kind: Kind
    var id: String
    var title: String
    var subtitle: String?
}

extension AppSettings {
    static func buildMetadata(for selection: FamilyActivitySelection) -> [AppSelectionMetadata] {
        var descriptors: [AppSelectionMetadata] = []
        func makeEntry(kind: AppSelectionMetadata.Kind, title: String, subtitle: String?) {
            descriptors.append(AppSelectionMetadata(kind: kind, id: UUID().uuidString, title: title, subtitle: subtitle))
        }
        
        for token in selection.applicationTokens {
            let application = ManagedSettings.Application(token: token)
            let rawBundle = application.bundleIdentifier
            let tokenString = applicationTokenString(token)
            let fallbackName = prettify(bundleIdentifier: rawBundle) ?? extractIdentifier(from: tokenString)
            let title = application.localizedDisplayName ?? fallbackName
            let subtitle = rawBundle ?? tokenString
            makeEntry(kind: .app, title: title, subtitle: subtitle)
        }

        for category in selection.categories {
            let title = category.localizedDisplayName ?? "App Category"
            makeEntry(kind: .category, title: title, subtitle: "Category")
        }

        for domain in selection.webDomains {
            if let domainString = domain.domain {
                makeEntry(kind: .domain, title: domainString, subtitle: "Web domain")
            }
        }
        
        if descriptors.isEmpty {
            return []
        }
        
        return descriptors.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    private static func prettify(bundleIdentifier: String?) -> String? {
        guard let identifier = bundleIdentifier else { return nil }
        if let short = identifier.split(separator: ".").last {
            return short.replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
        return identifier
    }
    
    private static func extractIdentifier(from debugDescription: String) -> String {
        if let range = debugDescription.range(of: "bundleIdentifier:") {
            let substring = debugDescription[range.upperBound...]
            return substring
                .trimmingCharacters(in: CharacterSet(charactersIn: " )"))
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
        return "Unknown App"
    }
    
    private static func applicationTokenString(_ token: ApplicationToken?) -> String? {
        guard let token else { return nil }
        return String(describing: token)
    }
    
    private static func applicationTokenString(_ token: ApplicationToken) -> String {
        String(describing: token)
    }
    
    private static func activityCategoryTokenString(_ token: ActivityCategoryToken?) -> String? {
        guard let token else { return nil }
        return String(describing: token)
    }
}

enum ChallengeType: String, CaseIterable, Codable {
    case stroop = "Stroop Test"
    case math = "Math Problems"
    case trivia = "Trivia Questions"
    case breath = "Breathing Exercise"
}
