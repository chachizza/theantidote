//
//  ContentView.swift
//  Antidote
//
//  Created by Mark T on 2025-09-02.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var authManager = AuthorizationManager.shared
    @State private var showingOnboarding = false
    @State private var settings = AppSettings.load()
    
    var body: some View {
        Group {
            if settings.isFirstLaunch {
                OnboardingView()
            } else if !authManager.isAuthorized {
                AuthorizationView()
            } else {
                DashboardView()
            }
        }
        .onAppear {
            checkFirstLaunch()
            authManager.checkAuthorizationStatus()
        }
    }
    
    private func checkFirstLaunch() {
        if settings.isFirstLaunch {
            settings.isFirstLaunch = false
            settings.save()
        }
    }
}

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var settings = AppSettings.load()
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePageView()
                .tag(0)
            FeaturesPageView()
                .tag(1)
            PermissionsPageView()
                .tag(2)
            GetStartedPageView()
                .tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to The Antidote")
                .font(.largeTitle.bold())
            
            Text("Your digital wellness companion")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Take control of your app usage with mindful challenges")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct FeaturesPageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("Key Features")
                .font(.largeTitle.bold())
            
            VStack(spacing: 24) {
                FeatureRow(icon: "timer", title: "Daily Limits", description: "Set custom time limits for your apps")
                FeatureRow(icon: "gamecontroller", title: "Mindful Challenges", description: "Complete challenges to unlock apps")
                FeatureRow(icon: "lock.shield", title: "Secure Settings", description: "Face ID/PIN protection for settings")
                FeatureRow(icon: "bell", title: "Smart Notifications", description: "Get warnings before limits are reached")
            }
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PermissionsPageView: View {
    @State private var isRequesting = false
    @StateObject private var authManager = AuthorizationManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Permissions Required")
                .font(.largeTitle.bold())
            
            VStack(spacing: 16) {
                Text("To help you manage app usage, we need permission to:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Monitor app usage time")
                    Text("• Block selected apps when limits are reached")
                    Text("• Send helpful notifications")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Button(action: {
                Task {
                    isRequesting = true
                    await authManager.requestAuthorization()
                    isRequesting = false
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                    }
                    Text("Grant Permission")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(authManager.isAuthorized ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isAuthorized)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct GetStartedPageView: View {
    @State private var settings = AppSettings.load()
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "rocket.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.largeTitle.bold())
            
            Text("Let's set up your first daily limit and select the apps you want to manage.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                settings.hasCompletedOnboarding = true
                settings.save()
            }) {
                HStack {
                    Text("Get Started")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct AuthorizationView: View {
    @StateObject private var authManager = AuthorizationManager.shared
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Authorization Required")
                .font(.largeTitle.bold())
            
            Text("The Antidote needs permission to monitor and manage your app usage. This helps you maintain healthy digital habits.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    isRequesting = true
                    await authManager.requestAuthorization()
                    isRequesting = false
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                    }
                    Text("Grant Permission")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
