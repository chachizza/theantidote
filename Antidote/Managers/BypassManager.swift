import Foundation
import ManagedSettings
import DeviceActivity
import FamilyControls

class BypassManager: ObservableObject {
    static let shared = BypassManager()
    
    @Published var isBypassActive = false
    @Published var remainingBypassTime: TimeInterval = 0
    @Published var canUseBypass = true
    @Published var passesUsedToday = 0
    
    private var bypassTimer: Timer?
    private let bypassDuration: TimeInterval = 5 * 60 // 5 minutes
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        let settings = AppSettings.load()
        settings.resetDailyCounters()
        passesUsedToday = settings.passesUsedToday
        canUseBypass = settings.canUsePass()
    }
    
    func requestBypass() async -> Bool {
        loadSettings()
        
        guard canUseBypass else {
            return false
        }
        
        // Update settings
        var settings = AppSettings.load()
        settings.usePass()
        
        // Activate bypass
        await activateBypass()
        return true
    }
    
    private func activateBypass() async {
        isBypassActive = true
        remainingBypassTime = bypassDuration
        
        // Disable shields temporarily
        await disableShields()
        
        // Start countdown timer
        bypassTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.remainingBypassTime -= 1
                
                if self.remainingBypassTime <= 0 {
                    self.deactivateBypass()
                }
            }
        }
    }
    
    private func deactivateBypass() {
        bypassTimer?.invalidate()
        bypassTimer = nil
        
        Task {
            await reEnableShields()
            await MainActor.run {
                self.isBypassActive = false
                self.remainingBypassTime = 0
            }
        }
    }
    
    private func disableShields() async {
        // This would disable the shields temporarily
        // Implementation depends on ManagedSettingsStore configuration
        print("Shields disabled temporarily")
    }
    
    private func reEnableShields() async {
        // This would re-enable the shields
        print("Shields re-enabled")
    }
    
    func cancelBypass() {
        bypassTimer?.invalidate()
        bypassTimer = nil
        
        Task {
            await reEnableShields()
            await MainActor.run {
                self.isBypassActive = false
                self.remainingBypassTime = 0
            }
        }
    }
    
    func getRemainingAttempts() -> Int {
        let settings = AppSettings.load()
        return 2 - settings.passesUsedToday
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}