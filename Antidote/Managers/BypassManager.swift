
import Foundation
import ManagedSettings

class BypassManager: ObservableObject {
    static let shared = BypassManager()
    let store = ManagedSettingsStore()

    private init() {}

    /// Grants a bypass for a specified duration, unshielding the apps.
    /// - Parameter minutes: The number of minutes to grant the bypass for.
    func grantBypass(for minutes: Int) {
        var settings = AppSettings.load()
        settings.bypassEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        settings.save()
        
        // Immediately unshield the apps and categories.
        // The DeviceActivityMonitor will respect the bypassEndTime and not re-shield them
        // until the bypass period is over.
        print("🔓 Bypass granted - removing all shields")
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
    
    /// Checks if a bypass is currently active.
    /// - Returns: True if a bypass is active, false otherwise.
    func isBypassActive() -> Bool {
        let settings = AppSettings.load()
        guard let endTime = settings.bypassEndTime else { return false }
        return endTime > Date()
    }
}
