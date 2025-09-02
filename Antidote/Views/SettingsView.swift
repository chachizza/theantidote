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
                Section(header: Text("Daily Limit")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Minutes per day")
                            Spacer()
                            Text("\(settings.dailyLimitMinutes)")
                                .foregroundColor(accentColor)
                                .font(.headline)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(settings.dailyLimitMinutes) },
                            set: { settings.dailyLimitMinutes = Int($0) }
                        ), in: 5...240, step: 5)
                        .tint(accentColor)
                        
                        Text("Set between 5-240 minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Challenge Type")) {
                    Picker("Challenge", selection: $settings.challengeType) {
                        ForEach(ChallengeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(accentColor)
                }
                
                Section(header: Text("Apps to Limit")) {
                    Button(action: {
                        Task {
                            let success = await authManager.authenticateWithBiometrics(reason: "Manage app restrictions")
                            if success {
                                showingActivityPicker = true
                            } else {
                                authError = true
                            }
                        }
                    }) {
                        HStack {
                            Text("Select Apps")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    if !settings.selectedApps.applications.isEmpty || !settings.selectedApps.categories.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Apps:")
                                .font(.headline)
                            
                            if !settings.selectedApps.applications.isEmpty {
                                ForEach(Array(settings.selectedApps.applications), id: \.self) { token in
                                    Text("• \(token.displayName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !settings.selectedApps.categories.isEmpty {
                                ForEach(Array(settings.selectedApps.categories), id: \.self) { category in
                                    Text("• \(category.localizedDisplayName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                Section(header: Text("Security")) {
                    Button(action: {
                        authManager.lock()
                        Task {
                            let success = await authManager.authenticateWithBiometrics(reason: "Unlock Settings")
                            if !success {
                                authError = true
                            }
                        }
                    }) {
                        HStack {
                            Text("Lock Settings")
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundColor(accentColor)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}