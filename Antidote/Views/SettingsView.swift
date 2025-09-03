import SwiftUI
import FamilyControls

struct SettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingActivityPicker = false
    @State private var settings = AppSettings.load()
    @State private var showAuthAlert = false
    @State private var authError = false
    
    private let accentColor = Color.blue
    
    var body: some View {
        NavigationView {
            Form {
                dailyLimitSection
                challengeTypeSection
                appsToLimitSection
                securitySection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .accentColor(accentColor)
            .sheet(isPresented: $showingActivityPicker) {
                FamilyActivityPicker(selection: $settings.selectedApps)
                    .onDisappear {
                        settings.save()
                        StorageManager.shared.saveFamilyActivitySelection(settings.selectedApps)
                    }
            }
            .alert("Authentication Required", isPresented: $authError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please authenticate to access settings")
            }
        }
    }
    
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
            Text("\(settings.dailyLimitMinutes)")
                .foregroundColor(accentColor)
                .font(.headline)
        }
    }
    
    private var dailyLimitSlider: some View {
        Slider(
            value: Binding(
                get: { Double(settings.dailyLimitMinutes) },
                set: { settings.dailyLimitMinutes = Int($0) }
            ),
            in: 5...240,
            step: 5
        )
        .tint(accentColor)
    }
    
    private var dailyLimitCaption: some View {
        Text("Set between 5-240 minutes")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var challengeTypeSection: some View {
        Section(header: Text("Challenge Type")) {
            Picker("Challenge", selection: $settings.challengeType) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(accentColor)
        }
    }
    
    private var appsToLimitSection: some View {
        Section(header: Text("Apps to Limit")) {
            selectAppsButton
            if hasSelectedApps {
                selectedAppsList
            }
        }
    }
    
    private var selectAppsButton: some View {
        Button(action: handleSelectApps) {
            HStack {
                Text("Select Apps")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
    
    private var selectedAppsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Selected Apps:")
                .font(.headline)
            
            appTokensList
            appCategoriesList
        }
        .padding(.top, 8)
    }
    
    private var appTokensList: some View {
        Group {
            ForEach(Array(settings.selectedApps.applications), id: \.self) { token in
                Text("• App Token")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var appCategoriesList: some View {
        Group {
            ForEach(Array(settings.selectedApps.categories), id: \.self) { category in
                Text("• Category Token")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var hasSelectedApps: Bool {
        !settings.selectedApps.applications.isEmpty || !settings.selectedApps.categories.isEmpty
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
    
    private func handleSelectApps() {
        Task {
            let success = await authManager.authenticateWithBiometrics(reason: "Manage app restrictions")
            if success {
                showingActivityPicker = true
            } else {
                authError = true
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}