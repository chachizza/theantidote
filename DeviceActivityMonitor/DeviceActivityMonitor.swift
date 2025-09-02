import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitor: DeviceActivityMonitorDelegate {
    static let shared = DeviceActivityMonitor()
    
    private init() {}
    
    func deviceActivityMonitor(_ monitor: DeviceActivityMonitor, didUpdate event: DeviceActivityEvent.Name) {
        Task {
            await handleActivityEvent(event)
        }
    }
    
    func deviceActivityMonitor(_ monitor: DeviceActivityMonitor, didUpdate activity: DeviceActivityName) {
        Task {
            await handleActivityUpdate(activity)
        }
    }
    
    private func handleActivityEvent(_ event: DeviceActivityEvent.Name) async {
        guard event == .dailyLimitReached else { return }
        
        // Get current settings
        let settings = AppSettings.load()
        
        // Activate shields for selected apps
        await activateShields(for: settings.selectedApps)
        
        // Send notification
        NotificationManager.shared.scheduleChallengeAvailableNotification()
    }
    
    private func handleActivityUpdate(_ activity: DeviceActivityName) async {
        guard activity == .dailyActivity else { return }
        
        // Check if we need to send warning
        let settings = AppSettings.load()
        let warningThreshold = settings.dailyLimitMinutes - 5
        
        // This would need to be implemented with actual usage tracking
        // For now, we'll just log the activity
        print("Daily activity updated")
    }
    
    private func activateShields(for selection: FamilyActivitySelection) async {
        let store = ManagedSettingsStore()
        
        // Configure shield settings
        var shieldConfiguration = ShieldConfiguration()
        shieldConfiguration.application = selection
        
        // Apply shield
        store.shield.applications = selection.applicationTokens
        store.shield.categories = selection.categoryTokens
        
        // Save to app group
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(shieldConfiguration) {
            UserDefaults(suiteName: AppSettings.appGroupIdentifier)?.set(encoded, forKey: "shieldConfiguration")
        }
    }
    
    func setupMonitoring() {
        // Create daily activity schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true,
            warningTime: nil
        )
        
        // Create event for daily limit
        let settings = AppSettings.load()
        let event = DeviceActivityEvent(
            applications: settings.selectedApps.applicationTokens,
            categories: settings.selectedApps.categoryTokens,
            threshold: DateComponents(minute: settings.dailyLimitMinutes)
        )
        
        // Start monitoring
        do {
            try DeviceActivityMonitor.shared.startMonitoring(.dailyActivity, during: schedule)
            try DeviceActivityMonitor.shared.startMonitoring(.dailyLimitReached, during: event)
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }
}

extension DeviceActivityName {
    static let dailyActivity = DeviceActivityName("dailyActivity")
    static let dailyLimitReached = DeviceActivityName("dailyLimitReached")
}

extension DeviceActivityEvent.Name {
    static let dailyLimitReached = DeviceActivityEvent.Name("dailyLimitReached")
}

struct ShieldConfiguration: Codable {
    var application: FamilyActivitySelection
    var customMessage: String = "Complete a challenge to unlock"
    var primaryButtonTitle: String = "Open The Antidote"
    var primaryButtonAction: String = "antidote://challenge"
}

// Extension entry point
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override init() {
        super.init()
        DeviceActivityMonitor.shared.delegate = self
        setupMonitoring()
    }
}