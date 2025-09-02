import SwiftUI

struct DashboardView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var settings = AppSettings.load()
    @State private var showingSettings = false
    @State private var showingChallenge = false
    
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
                    
                    if settings.selectedApps.applications.isEmpty && settings.selectedApps.categories.isEmpty {
                        Text("No apps selected")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    } else {
                        Text("\(settings.selectedApps.applications.count + settings.selectedApps.categories.count) items")
                            .font(.title2.bold())
                            .foregroundColor(accentColor)
                    }
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    Text("Challenge Type")
                        .font(.headline)
                    Text(settings.challengeType.rawValue)
                        .font(.title3.bold())
                        .foregroundColor(accentColor)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // Action Buttons
            VStack(spacing: 16) {
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
                
                Button(action: {
                    showingChallenge = true
                }) {
                    HStack {
                        Image(systemName: "brain")
                        Text("Start Challenge")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingChallenge) {
            ChallengeSelectionView()
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}