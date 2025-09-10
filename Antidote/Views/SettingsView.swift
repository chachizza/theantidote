
import SwiftUI
import FamilyControls
import DeviceActivity

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingActivityPicker = false
    @State private var settings = AppSettings.load()
    @State private var showAuthAlert = false
    @State private var authError = false
    
    // Make settings reactive
    @State private var dailyLimit: Double = 45.0
    
    private let accentColor = Color.blue
    
    var body: some View {
        NavigationView {
            Form {
                dailyLimitSection
                appsToLimitSection
                securitySection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .accentColor(accentColor)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingActivityPicker) {
                FamilyActivityPickerView()
                    .onDisappear {
                        // Refresh settings to show updated selections
                        settings = AppSettings.load()
                        print("💾 Family Activity selections updated")
                        onPickerDismiss()
                    }
            }
            .alert("Authentication Required", isPresented: $authError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please authenticate to access settings")
            }
            .onAppear {
                // Load fresh settings when view appears
                settings = AppSettings.load()
                // Initialize reactive state variables
                dailyLimit = Double(settings.dailyLimitMinutes)
                print("📱 Settings loaded - Daily: \(settings.dailyLimitMinutes) minutes")
                print("📱 UI state - Daily: \(Int(dailyLimit)) minutes")
            }
            .onChange(of: settings.dailyLimitMinutes) { _, newValue in
                // Update UI state when settings change
                dailyLimit = Double(newValue)
                print("🔄 Syncing UI - Daily limit updated to: \(newValue)")
            }
            .onDisappear {
                // Save settings when view disappears
                settings.save()
            }
        }
    }
    
    private func onPickerDismiss() {
        settings.save()
        startMonitoring()
    }
    
    private func startMonitoring() {
        let selection = settings.selectedApps
        
        print("🔄 Starting monitoring...")
        print("  Daily limit: \(settings.dailyLimitMinutes) minutes")
        print("  Applications: \(selection.applicationTokens.count)")
        
        // Check if we have any apps selected
        let hasAppsSelected = !selection.applicationTokens.isEmpty
        
        guard hasAppsSelected else {
            print("❌ No apps or categories selected - monitoring not started")
            return
        }

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
        
        let thresholdComps = DateComponents(minute: settings.dailyLimitMinutes)
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: thresholdComps
        )
        
        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(.daily, during: schedule, events: [.timeLimitReached: event])
            print("✅ Monitoring started successfully!")
            
            // Monitoring setup complete
            print("✅ DeviceActivity monitoring configured successfully")
        } catch {
            print("❌ Error starting monitoring: \(error)")
        }
    }
    
    
    // ... The rest of the view body remains the same ...
    
    private var dailyLimitSection: some View {
        Section(header: Text("Daily Limit")) {
            VStack(alignment: .leading, spacing: 8) {
                dailyLimitHeader
                dailyLimitSlider
                dailyLimitCaption
            }
            .padding(.vertical, 8)
        }
    }
    
    private var dailyLimitHeader: some View {
        HStack {
            Text("Minutes per day")
            Spacer()
            Text("\(Int(dailyLimit))")
                .foregroundColor(accentColor)
                .font(.headline)
        }
    }
    
    private var dailyLimitSlider: some View {
        Slider(
            value: $dailyLimit,
            in: 1...240,
            step: 1
        )
        .tint(accentColor)
        .onChange(of: dailyLimit) { _, newValue in
            settings.dailyLimitMinutes = Int(newValue)
            settings.save()
            print("💾 Daily limit changed to: \(Int(newValue)) minutes")
            print("💾 Settings object now has: \(settings.dailyLimitMinutes) minutes")
            // Force update the settings object to ensure sync
            DispatchQueue.main.async {
                settings = AppSettings.load()
                print("💾 Reloaded settings: \(settings.dailyLimitMinutes) minutes")
            }
            // Restart monitoring with new limit
            startMonitoring()
        }
    }
    
    private var dailyLimitCaption: some View {
        Text("Set between 1-240 minutes")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var appsToLimitSection: some View {
        Section(header: Text("Apps to Block")) {
            // Apple's Family Activity Picker (Only working option)
            Button(action: {
                showingActivityPicker = true
            }) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Select Apps to Block")
                            .foregroundColor(.primary)
                            .font(.headline)
                        Text("Choose specific apps like Instagram, TikTok, etc.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            // Show current Family Activity selections
            let familySelection = settings.selectedApps
            if !familySelection.applicationTokens.isEmpty {
                familyActivitySelectionDisplay
            } else {
                Text("No apps selected yet")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var clearAllButton: some View {
        Button(action: {
            // Clear Family Activity selections
            settings.selectedApps = FamilyActivitySelection()
            settings.save()
            print("🗑️ Cleared all app selections")
        }) {
            HStack {
                Image(systemName: "trash.fill")
                Text("Clear All Selections")
                Spacer()
            }
        }
        .foregroundColor(.red)
    }
    
    private var securitySection: some View {
        Section(header: Text("Security")) {
            Button(action: handleLockSettings) {
                HStack {
                    Text("Lock Settings")
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundColor(accentColor)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("The Antidote")
                    .font(.headline)
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    
    private func handleLockSettings() {
        authManager.lock()
        Task {
            let success = await authManager.authenticateWithBiometrics(reason: "Unlock Settings")
            if !success {
                authError = true
            }
        }
    }
    
    private var familyActivitySelectionDisplay: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    Text("Selected Apps")
                        .font(.headline)
                    Spacer()
                    let familySelection = settings.selectedApps
                    Text("\(familySelection.applicationTokens.count)")
                        .font(.headline.bold())
                        .foregroundColor(.green)
                }
                
                let familySelection = settings.selectedApps
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ \(familySelection.applicationTokens.count) apps selected")
                        .font(.callout)
                        .foregroundColor(.green)
                    Text("These will be blocked when you reach your daily limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGreen).opacity(0.1))
            .cornerRadius(8)
            
            clearAllButton
        }
    }
    
}

// Add names for the activity and event to a shared scope
extension DeviceActivityName {
    static let daily = Self("daily")
}

extension DeviceActivityEvent.Name {
    static let timeLimitReached = Self("timeLimitReached")
}
