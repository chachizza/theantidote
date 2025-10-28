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
    @State private var isRequestingAuthorization = false
    
    var body: some View {
        ZStack {
            RetroTheme.Palette.background
                .ignoresSafeArea()
            
            switch authManager.authorizationStatus {
            case .approved:
                HomeView()
            case .denied:
                AuthorizationPromptView(
                    headline: "authorization required",
                    message: "We need Screen Time permission to lock your selected apps when the timer expires.",
                    accent: RetroTheme.Palette.locked,
                    isRequesting: $isRequestingAuthorization,
                    action: requestAuthorization
                )
            default:
                AuthorizationPromptView(
                    headline: "power up the antidote",
                    message: "Grant Screen Time access so the control panel can monitor and lock your chosen apps.",
                    accent: RetroTheme.Palette.secondaryAccent,
                    isRequesting: $isRequestingAuthorization,
                    action: requestAuthorization
                )
            }
        }
        .onAppear {
            authManager.checkAuthorizationStatus()
        }
    }
    
    private func requestAuthorization() {
        Task { @MainActor in
            isRequestingAuthorization = true
            await authManager.requestAuthorization()
            isRequestingAuthorization = false
        }
    }
}

private struct AuthorizationPromptView: View {
    var headline: String
    var message: String
    var accent: Color
    @Binding var isRequesting: Bool
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)
            VStack(spacing: 22) {
                Text(headline.uppercased())
                    .font(RetroTheme.Typography.title(20))
                    .foregroundColor(accent)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(RetroTheme.Typography.body(13))
                    .foregroundColor(RetroTheme.Palette.text.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Button {
                    action()
                } label: {
                    if isRequesting {
                        ProgressView()
                            .tint(RetroTheme.Palette.text)
                    } else {
                        Text("Grant Permission")
                    }
                }
                .buttonStyle(RetroButtonStyle(kind: .primary, cornerRadius: 30, shadowRadius: 12))
                .disabled(isRequesting)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(RetroTheme.Palette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(RetroTheme.Palette.panelBorder, lineWidth: 2)
                    )
            )
            Text("Screen Time data stays on device. No accounts. No tracking.")
                .font(RetroTheme.Typography.body(10))
                .foregroundColor(RetroTheme.Palette.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
    }
}
