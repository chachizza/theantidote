//
//  DoseSetupView.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import SwiftUI
import FamilyControls

struct DoseSetupView: View {
    @Binding var settings: AppSettings
    var onDismiss: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var localLimit: Double = 45
    @State private var showingActivityPicker = false
    
    init(settings: Binding<AppSettings>, onDismiss: (() -> Void)? = nil) {
        self._settings = settings
        self.onDismiss = onDismiss
        self._localLimit = State(initialValue: Double(settings.wrappedValue.dailyLimitMinutes))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Text("Daily Dose Configuration")
                        .font(RetroTheme.Typography.title(18))
                        .foregroundColor(RetroTheme.Palette.secondaryAccent)
                        .padding(.top, 12)
                    
                    RetroPanel(title: "Time Allocation") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Minutes Per Day".uppercased())
                                .font(RetroTheme.Typography.body(14))
                                .foregroundColor(RetroTheme.Palette.text.opacity(0.9))
                            
                            Text("\(Int(localLimit)) MIN")
                                .font(RetroTheme.Typography.title(24))
                                .foregroundColor(RetroTheme.Palette.primaryAccent)
                            
                            Slider(
                                value: $localLimit,
                                in: 15...240,
                                step: 5
                            )
                            .tint(RetroTheme.Palette.primaryAccent)
                            .onChange(of: localLimit) { _, newValue in
                                settings.dailyLimitMinutes = Int(newValue)
                                settings.save()
                            }
                            
                            Text("Tune your daily dose between 15 and 240 minutes.")
                                .font(RetroTheme.Typography.body(12))
                                .foregroundColor(RetroTheme.Palette.text.opacity(0.7))
                        }
                    }
                    
                    RetroPanel(title: "") {
                        VStack(alignment: .leading, spacing: 18) {
                            RetroAppGrid(items: HomeView.displayItems(for: settings))
                            
                            Button {
                                showingActivityPicker = true
                            } label: {
                                Label("Choose Apps To Lock", systemImage: "plus")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(RetroButtonStyle(kind: .secondary))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(RetroTheme.Palette.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismissView()
                    }
                    .font(RetroTheme.Typography.body(14))
                    .foregroundColor(RetroTheme.Palette.text)
                }
            }
        }
        .sheet(isPresented: $showingActivityPicker, onDismiss: {
            settings = AppSettings.load()
            localLimit = Double(settings.dailyLimitMinutes)
        }) {
            FamilyActivityPickerView()
                .preferredColorScheme(.dark)
        }
        .onDisappear {
            settings.save()
        }
    }
    
    private func dismissView() {
        settings.save()
        onDismiss?()
        dismiss()
    }
}
