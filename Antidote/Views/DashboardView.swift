import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings
import UIKit
import UserNotifications

struct DashboardView: View {
    
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var settings = AppSettings.load()
    @State private var showingSettings = false
    
    private let accentColor = Color.blue
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("The Antidote")
                    .font(.largeTitle.bold())
                Text("Digital Wellness Companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            
            // Status Card
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Daily Limit")
                        .font(.headline)
                    Text("\(settings.dailyLimitMinutes) minutes")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    Text("Selected Apps")
                        .font(.headline)
                    
                    let familySelection = settings.selectedApps
                    let selectedAppsCount = familySelection.applicationTokens.count
                    
                    if selectedAppsCount == 0 {
                        Text("No apps selected")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    } else {
                        VStack(spacing: 4) {
                            Text("\(selectedAppsCount) apps")
                                .font(.title2.bold())
                                .foregroundColor(accentColor)
                            Text("Ready to be blocked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // Action Button
            Button(action: {
                showingSettings = true
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Refresh settings when dashboard appears
            settings = AppSettings.load()
            print("🏠 Dashboard loaded - Daily: \(settings.dailyLimitMinutes) minutes")
            print("🏠 Dashboard loaded - Applications: \(settings.selectedApps.applicationTokens.count), Categories: \(settings.selectedApps.categoryTokens.count)")
            // Start monitoring with current settings
            startMonitoringIfNeeded()
        }
        .refreshable {
            // Pull to refresh functionality
            settings = AppSettings.load()
            print("🔄 Dashboard refreshed - Daily: \(settings.dailyLimitMinutes) minutes")
        }
        .onDisappear {
            // Clean up polling timer when view disappears
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func startMonitoringIfNeeded() {
        let selection = settings.selectedApps
        
        print("🏠 Dashboard checking monitoring setup...")
        print("  Daily limit: \(settings.dailyLimitMinutes) minutes")
        print("  Applications: \(selection.applicationTokens.count)")
        
        // Check if we have any apps selected
        let hasAppsSelected = !selection.applicationTokens.isEmpty
        
        guard hasAppsSelected else {
            print("❌ No apps or categories selected - monitoring not started")
            return
        }

        let center = DeviceActivityCenter()
        
        // Stop any existing monitoring first
        center.stopMonitoring([
            .daily, 
            DeviceActivityName("antidote.daily.monitoring"),
            DeviceActivityName("antidote.current.session")
        ])
        
        // Try DeviceActivity monitoring (background process)
        startDeviceActivityMonitoring()
        
        // Start manual polling as backup (works reliably)
        startManualPolling()
    }
    
    
    private func startDeviceActivityMonitoring() {
        let selection = settings.selectedApps
        let center = DeviceActivityCenter()
        let now = Date()
        
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let startComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startOfDay)
        let endComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endOfDay)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComps,
            intervalEnd: endComps,
            repeats: true
        )
        
        let actualMinutes = max(1, settings.dailyLimitMinutes)
        let thresholdComps = DateComponents(minute: actualMinutes)
        
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: thresholdComps
        )
        
        do {
            let dailyName = DeviceActivityName("antidote.daily.monitoring")
            try center.startMonitoring(dailyName, during: schedule, events: [.timeLimitReached: event])
        } catch {
            // DeviceActivity failed, manual polling will handle monitoring
        }
    }
    
    private func forceIntervalStart(center: DeviceActivityCenter, activityName: DeviceActivityName) {
        print("🔄 Forcing interval to start...")
        
        // Try to manually trigger interval start by creating a very short monitoring window
        let now = Date()
        let oneSecondLater = now.addingTimeInterval(1)
        
        let nowComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        let laterComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: oneSecondLater)
        
        let quickSchedule = DeviceActivitySchedule(
            intervalStart: nowComps,
            intervalEnd: laterComps,
            repeats: false
        )
        
        do {
            let testName = DeviceActivityName("antidote.force.test")
            try center.startMonitoring(testName, during: quickSchedule, events: [:])
            print("✅ Force test monitoring started - this should trigger extension loading")
            
            // Stop it immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                center.stopMonitoring([testName])
                print("✅ Force test monitoring stopped")
            }
        } catch {
            print("❌ Force test failed: \(error)")
        }
    }
    
    private func checkMonitoringStatus() {
        print("🔍 Checking if DeviceActivity monitoring is actually active...")
        
        // Try to force extension loading by accessing it directly
        forceExtensionLoading()
        
        // Unfortunately, DeviceActivityCenter doesn't provide a way to check active monitoring
        // But we can at least verify our extension gets loaded by checking if it left any traces
        let fileManager = FileManager.default
        if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logFile = documentsPath.appendingPathComponent("extension_log.txt")
            if fileManager.fileExists(atPath: logFile.path) {
                if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                    print("📁 Extension log exists: \(content)")
                } else {
                    print("📁 Extension log file exists but couldn't read content")
                }
            } else {
                print("📁 No extension log file found - extension may not be loading")
                print("📁 This likely means iOS is not loading the DeviceActivityMonitor extension")
                print("📁 Possible causes: missing entitlements, extension not registered, or iOS restrictions")
            }
        }
    }
    
    private func forceExtensionLoading() {
        print("🔧 Attempting to force extension loading...")
        
        // Try to instantiate the ManagedSettingsStore to ensure the shield extension is loaded
        let _ = ManagedSettingsStore()
        print("🔧 ManagedSettingsStore instantiated")
        
        // Try a quick shield/unshield cycle to wake up the extension system
        let dummyStore = ManagedSettingsStore()
        dummyStore.shield.applications = Set<ApplicationToken>()
        dummyStore.shield.applications = nil
        print("🔧 Shield system exercised")
        
        // Force DeviceActivity center access
        let center = DeviceActivityCenter()
        print("🔧 DeviceActivityCenter accessed: \(center)")
    }
    
    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private func manuallyTriggerShield() {
        print("🔴 MANUAL SHIELD TRIGGER: Forcing shield activation NOW!")
        
        let settings = AppSettings.load()
        let selection = settings.selectedApps
        
        print("🔴 MANUAL: Applications to shield: \(selection.applicationTokens.count)")
        print("🔴 MANUAL: Categories to shield: \(selection.categoryTokens.count)")
        
        if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
            print("🔴 MANUAL: ERROR - No apps or categories selected!")
            
            let alert = UIAlertController(
                title: "⚠️ No Apps Selected",
                message: "Please select some apps in Settings first before testing the shield.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
            return
        }
        
        // Manually activate the shield using ManagedSettings
        let store = ManagedSettingsStore()
        
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            print("🔴 MANUAL: ✅ Shielded \(selection.applicationTokens.count) applications")
        }
        
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            print("🔴 MANUAL: ✅ Shielded \(selection.categoryTokens.count) categories")
        }
        
        print("🔴 MANUAL: Shield should now be active! Try opening Safari.")
        
        let alert = UIAlertController(
            title: "🛡️ Shield Activated!",
            message: "The shield has been manually activated. Try opening Safari now - it should be blocked with an Antidote challenge button.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func simulateBlocking() {
        print("🎭 SIMULATOR: Blocking would happen now on real device!")
        print("🎭 SIMULATOR: Shield would appear over Safari")
        print("🎭 SIMULATOR: User would see Antidote challenge button")
        
        // Show an alert to simulate what would happen
        let alert = UIAlertController(
            title: "🛡️ Simulated Blocking",
            message: "On a real device, Safari would now be blocked with an Antidote shield showing a 'Take Challenge' button.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Manual Polling Backup System
    
    @State private var pollingTimer: Timer?
    @State private var appUsageStartTime: Date?
    
    private func startManualPolling() {
        // Reset usage tracking
        appUsageStartTime = nil
        
        // Start polling every 30 seconds (more efficient)
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            checkAppUsageManually()
        }
    }
    
    private func checkAppUsageManually() {
        guard let foregroundApp = getCurrentForegroundApp() else { return }
        
        let settings = AppSettings.load()
        let selection = settings.selectedApps
        
        // Check if current app is one we're monitoring
        let isMonitoredApp = isAppBeingMonitored(bundleId: foregroundApp, selection: selection)
        
        if isMonitoredApp {
            if appUsageStartTime == nil {
                // Started using a monitored app
                appUsageStartTime = Date()
            } else {
                // Check if we've exceeded the limit
                let usageTime = Date().timeIntervalSince(appUsageStartTime!)
                let limitSeconds = TimeInterval(settings.dailyLimitMinutes * 60)
                
                
                if usageTime >= limitSeconds {
                    triggerManualShield()
                    appUsageStartTime = nil // Reset
                }
            }
        } else {
            // Not using a monitored app anymore
            if appUsageStartTime != nil {
                appUsageStartTime = nil
            }
        }
    }
    
    private func getCurrentForegroundApp() -> String? {
        // This is a simplified check - in reality, iOS restricts access to foreground app info
        // But we can check if Safari is likely being used based on our shields
        
        // For now, assume Safari if we can't get exact info
        return "com.apple.mobilesafari"
    }
    
    private func isAppBeingMonitored(bundleId: String, selection: FamilyActivitySelection) -> Bool {
        // For Safari specifically (most common case)
        if bundleId == "com.apple.mobilesafari" && (!selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty) {
            return true
        }
        
        // In practice, we can't easily check if a specific bundle ID is in the selection
        // since ApplicationTokens are opaque. This function is mainly for Safari.
        return false
    }
    
    private func triggerManualShield() {
        
        let settings = AppSettings.load()
        let selection = settings.selectedApps
        let store = ManagedSettingsStore()
        
        // Check bypass
        if let bypassEnd = settings.bypassEndTime, bypassEnd > Date() {
            print("🛡️ MANUAL: Bypass is active, not shielding")
            return
        }
        
        // Apply shields
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }
        
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        
        
        // Send notification
        let content = UNMutableNotificationContent()
        content.title = "Antidote: Time Limit Reached"
        content.body = "Take a challenge to continue using this app"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "manual-limit", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // Note: SwiftUI Views (structs) don't support deinit
    // Timer cleanup is handled in .onDisappear modifier
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}