//
//  HomeView.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import Combine

struct HomeView: View {
    
    @State private var settings = AppSettings.load()
    @State private var doseState: DoseState = .idle
    @State private var boosterState: BoosterState = .hidden
    @State private var isPowerOn = false
    @State private var showDoseSetup = false
    @State private var showChallenge = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var boosterMessage: String?
    @State private var boosterMessageOpacity: Double = 0
    @State private var glowPulse = false
    @State private var appMetadata: [AppDisplayItem] = []
    
    private let bypassManager = BypassManager.shared
    private let sessionManager = DoseSessionManager.shared
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let soundPlayer = RetroSoundPlayer()
    
    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    mainPanel
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
            .safeAreaPadding(.top, 28)
            .safeAreaPadding(.bottom, 40)
            .safeAreaPadding(.horizontal, 22)
            
            if doseState == .locked {
                lockedOverlay
            }
            
            if let boosterMessage {
                boosterBanner(message: boosterMessage)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            synchronizeSettingsFromStorage(resetTimerIfIdle: true)
        }
        .onReceive(timer) { _ in
            guard doseState == .running else { return }
            guard timeRemaining > 0 else {
                triggerLockdown()
                return
            }
            timeRemaining -= 1
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .appSettingsDidChange)
                .receive(on: RunLoop.main)
        ) { _ in
            synchronizeSettingsFromStorage(resetTimerIfIdle: true)
        }
        .sheet(isPresented: $showDoseSetup, onDismiss: {
            synchronizeSettingsFromStorage(resetTimerIfIdle: true)
        }) {
            DoseSetupView(settings: $settings) {
                synchronizeSettingsFromStorage(resetTimerIfIdle: true)
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showChallenge, onDismiss: {
            if boosterState == .hidden && doseState == .locked {
                // Challenge dismissed without result, remain locked
                triggerLockdownFeedback(message: "NEED THAT BOOSTER? TRY AGAIN.")
            }
        }) {
            ChallengeView { outcome in
                handleChallengeOutcome(outcome)
                showChallenge = false
            }
        }
        .onChange(of: doseState) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                glowPulse = newValue == .running
            }
        }
    }
}

// MARK: - Panels & Sections

private extension HomeView {
    
    var backgroundGradient: some View {
        LinearGradient(
            colors: [
                RetroTheme.Palette.background,
                doseState == .locked ? RetroTheme.Palette.locked.opacity(0.5) : RetroTheme.Palette.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var mainPanel: some View {
        VStack(spacing: 32) {
            headerPanel
            statusPanel
            appGridPanel
            actionPanel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: 420, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(RetroTheme.Palette.panel.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(RetroTheme.Palette.panelBorder, lineWidth: 2)
                )
        )
        .shadow(color: RetroTheme.Palette.highlight.opacity(0.18), radius: 24, x: 0, y: 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 32)
        .padding(.bottom, 64)
    }
    
    var headerPanel: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("THE ANTIDOTE")
                .font(RetroTheme.Typography.title(24))
                .foregroundColor(RetroTheme.Palette.text)
                .multilineTextAlignment(.center)
            RetroToggle(
                isOn: $isPowerOn,
                label: nil,
                trackSize: CGSize(width: 200, height: 74),
                knobSize: CGSize(width: 52, height: 52)
            )
            .frame(maxWidth: .infinity)
            .onChange(of: isPowerOn) { _, newValue in
                soundPlayer.playToggle()
                if newValue {
                    startDose()
                } else {
                    stopDose()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(RetroTheme.Palette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(RetroTheme.Palette.panelBorder, lineWidth: 2)
                )
                .shadow(color: RetroTheme.Palette.highlight.opacity(0.25), radius: 20, x: 0, y: 14)
        )
    }
    
    var statusPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("TIME REMAINING")
                        .font(RetroTheme.Typography.body(11))
                        .foregroundColor(RetroTheme.Palette.mutedText)
                    Text(formattedTime(remaining: timeRemaining))
                        .font(RetroTheme.Typography.title(34))
                        .foregroundColor(timeColor)
                        .shadow(color: glowColor.opacity(glowPulse ? 0.9 : 0.2), radius: glowPulse ? 22 : 0)
                        .animation(.easeInOut(duration: 1.4), value: glowPulse)
                }
                Spacer()
                statusBadge
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(RetroTheme.Palette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(RetroTheme.Palette.panelBorder, lineWidth: 2)
                )
        )
    }
    
    var statusBadge: some View {
        Text(statusLabel)
            .font(RetroTheme.Typography.body(12))
            .foregroundColor(RetroTheme.Palette.text)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(glowColor)
            .clipShape(Capsule())
            .shadow(color: glowColor.opacity(0.4), radius: 14, x: 0, y: 6)
    }
    
    var appGridPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("LOCKED APPS")
                .font(RetroTheme.Typography.title(16))
                .foregroundColor(RetroTheme.Palette.secondaryAccent)
            RetroAppGrid(items: appMetadata)
        }
    }
    
    var actionPanel: some View {
        VStack(spacing: 18) {
            Button {
                soundPlayer.playButton()
                showDoseSetup = true
            } label: {
                Text("SETTINGS")
            }
            .buttonStyle(RetroButtonStyle(kind: .secondary, cornerRadius: 30, shadowRadius: 14))
        }
    }
}

// MARK: - Overlay Elements

private extension HomeView {
    var lockedOverlay: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            RetroTheme.Palette.locked.opacity(0.8),
                            RetroTheme.Palette.locked.opacity(0.6),
                            RetroTheme.Palette.locked.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.3))
                .blendMode(.screen)
                .animation(
                    .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                    value: doseState
                )
            
            VStack(spacing: 24) {
                Text("🔒  SYSTEM LOCKDOWN ACTIVE")
                    .font(RetroTheme.Typography.title(20))
                    .foregroundColor(RetroTheme.Palette.text)
                
                Text("Your dose is complete. Come back tomorrow.")
                    .font(RetroTheme.Typography.body(14))
                    .foregroundColor(RetroTheme.Palette.text.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button("Take the Challenge") {
                    boosterState = .presented
                    showChallenge = true
                }
                .buttonStyle(RetroButtonStyle(kind: .warning))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(RetroTheme.Palette.background.opacity(0.9))
                    )
                    .overlay(GlitchOverlay().clipShape(RoundedRectangle(cornerRadius: 24)))
            )
            .padding(40)
        }
    }
    
    func boosterBanner(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(RetroTheme.Typography.title(16))
                .foregroundColor(RetroTheme.Palette.background)
                .padding(.vertical, 16)
                .padding(.horizontal, 28)
                .background(RetroTheme.Palette.secondaryAccent)
                .clipShape(Capsule())
                .shadow(color: RetroTheme.Palette.secondaryAccent.opacity(0.7), radius: 20)
                .opacity(boosterMessageOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        boosterMessageOpacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            boosterMessageOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            boosterMessage = nil
                        }
                    }
                }
            Spacer().frame(height: 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - State Helpers

private extension HomeView {
    var statusLabel: String {
        switch doseState {
        case .idle: return "IDLE"
        case .running: return "RUNNING"
        case .locked: return "LOCKED"
        }
    }
    
    var glowColor: Color {
        switch doseState {
        case .idle:
            return RetroTheme.Palette.secondaryAccent
        case .running:
            return RetroTheme.Palette.primaryAccent
        case .locked:
            return RetroTheme.Palette.locked
        }
    }
    
    var timeColor: Color {
        switch doseState {
        case .idle: return RetroTheme.Palette.text
        case .running: return RetroTheme.Palette.primaryAccent
        case .locked: return RetroTheme.Palette.locked
        }
    }
    
    func formattedTime(remaining: TimeInterval) -> String {
        guard remaining > 0 else { return "0h 00m" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return String(format: "%02dh %02dm", hours, minutes)
    }
    
    func synchronizeSettingsFromStorage(resetTimerIfIdle: Bool = false) {
        loadSettings()
        updateAppBadges()
        if resetTimerIfIdle && doseState != .running {
            timeRemaining = TimeInterval(settings.dailyLimitMinutes * 60)
        }
    }
    
    func loadSettings() {
        settings = AppSettings.load()
    }
    
    func updateAppBadges() {
        appMetadata = HomeView.displayItems(for: settings)
        let metadata = AppSettings.buildMetadata(for: settings.selectedApps)
        if !metadata.isEmpty && metadata != settings.selectionMetadata {
            settings.selectionMetadata = metadata
            settings.save()
            appMetadata = HomeView.displayItems(for: settings)
        }
        let tokens = settings.selectedApps.applicationTokens
        print("🔎 HomeView badges refreshed with \(tokens.count) app tokens")
        tokens.forEach { token in
            let app = ManagedSettings.Application(token: token)
            let descriptor = AppSettings.debugDescription(for: token)
            print("   • token: \(descriptor)")
            print("     ↳ bundle: \(app.bundleIdentifier ?? "nil"), name: \(app.localizedDisplayName ?? "nil")")
        }
    }
    
    func startDose() {
        guard !settings.selectedApps.applicationTokens.isEmpty else {
            triggerLockdownFeedback(message: "ADD APPS BEFORE STARTING.")
            isPowerOn = false
            return
        }
        
        timeRemaining = TimeInterval(settings.dailyLimitMinutes * 60)
        withAnimation(.spring(duration: 0.5)) {
            doseState = .running
            isPowerOn = true
        }
        boosterState = .hidden
        applyShieldingIfNeeded()
    }
    
    func stopDose() {
        withAnimation(.easeInOut(duration: 0.4)) {
            doseState = .idle
            isPowerOn = false
            timeRemaining = TimeInterval(settings.dailyLimitMinutes * 60)
        }
        boosterState = .hidden
        removeShields()
    }
    
    func triggerLockdown() {
        withAnimation(.easeInOut(duration: 0.6)) {
            doseState = .locked
            isPowerOn = false
            timeRemaining = 0
        }
        boosterState = .hidden
        soundPlayer.playLockClick()
        applyShieldingIfNeeded()
    }
    
    func triggerLockdownFeedback(message: String) {
        boosterMessageOpacity = 0
        boosterMessage = message
    }
    
    func handleChallengeOutcome(_ outcome: ChallengeView.Outcome) {
        switch outcome {
        case .success:
            boosterState = .granted
            grantBooster()
            triggerLockdownFeedback(message: "BOOSTER GRANTED +5M")
        case .failure:
            boosterState = .failed
            triggerLockdownFeedback(message: "LOCKDOWN STILL ACTIVE")
        case .cancelled:
            boosterState = .hidden
        }
    }
    
    func grantBooster() {
        bypassManager.grantBypass(for: 5)
        withAnimation(.easeInOut(duration: 0.5)) {
            timeRemaining = TimeInterval(5 * 60)
            doseState = .running
            isPowerOn = true
        }
        sessionManager.startSession(settings: settings)
    }
    
    func applyShieldingIfNeeded() {
        switch doseState {
        case .idle:
            sessionManager.stopSession()
        case .running:
            sessionManager.startSession(settings: settings)
        case .locked:
            sessionManager.applyImmediateShield(selection: settings.selectedApps)
        }
    }
    
    func removeShields() {
        sessionManager.stopSession()
    }
}

// MARK: - App Names Helpers

extension HomeView {
    static func displayItems(for settings: AppSettings) -> [AppDisplayItem] {
        let selection = settings.selectedApps
        var seenIDs = Set<String>()
        func uniqueID(from base: String) -> String {
            var candidate = base
            var counter = 1
            while seenIDs.contains(candidate) {
                counter += 1
                candidate = "\(base)-\(counter)"
            }
            seenIDs.insert(candidate)
            return candidate
        }
        
        func prettify(_ bundle: String?) -> String? {
            guard let bundle else { return nil }
            if let short = bundle.split(separator: ".").last {
                return short.replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
            }
            return bundle
        }
        
        var items: [AppDisplayItem] = []
        var seenAppTokenIDs = Set<String>()
        for token in selection.applicationTokens {
            let tokenID = AppSettings.debugDescription(for: token)
            guard seenAppTokenIDs.insert(tokenID).inserted else { continue }
            let app = ManagedSettings.Application(token: token)
            let bundle = app.bundleIdentifier
            let fallback = prettify(bundle) ?? tokenID
            let name = app.localizedDisplayName ?? fallback
            let identifier = uniqueID(from: bundle ?? tokenID)
            items.append(AppDisplayItem(kind: .app, id: identifier, title: name, subtitle: bundle, applicationToken: token, categoryToken: nil, webDomainToken: nil))
        }
        
        var seenCategoryIDs = Set<String>()
        for token in selection.categoryTokens {
            let tokenID = AppSettings.debugDescription(for: token)
            guard seenCategoryIDs.insert(tokenID).inserted else { continue }
            let category = ManagedSettings.ActivityCategory(token: token)
            let name = category.localizedDisplayName ?? "App Category"
            let identifier = uniqueID(from: tokenID)
            items.append(AppDisplayItem(kind: .category, id: identifier, title: name, subtitle: "Category", applicationToken: nil, categoryToken: token, webDomainToken: nil))
        }
        
        var seenDomainIDs = Set<String>()
        for token in selection.webDomainTokens {
            let tokenID = AppSettings.debugDescription(for: token)
            guard seenDomainIDs.insert(tokenID).inserted else { continue }
            let domain = ManagedSettings.WebDomain(token: token)
            let name = domain.domain ?? "Web Domain"
            let identifier = uniqueID(from: tokenID)
            items.append(AppDisplayItem(kind: .domain, id: identifier, title: name, subtitle: "Web domain", applicationToken: nil, categoryToken: nil, webDomainToken: token))
        }
        
        if items.isEmpty {
            return [
                AppDisplayItem(
                    kind: .placeholder,
                    id: UUID().uuidString,
                    title: "No selections yet",
                    subtitle: "Tap settings to choose apps",
                    applicationToken: nil,
                    categoryToken: nil,
                    webDomainToken: nil
                )
            ]
        }
        
        items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        return items
    }
}

struct AppDisplayItem: Identifiable, Hashable {
    enum Kind: Hashable {
        case app
        case category
        case domain
        case placeholder
    }
    var kind: Kind
    var id: String
    var title: String
    var subtitle: String?
    var applicationToken: ApplicationToken?
    var categoryToken: ActivityCategoryToken?
    var webDomainToken: WebDomainToken?
}

// MARK: - Supporting Views
struct RetroAppGrid: View {
    var items: [AppDisplayItem]
    
    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 80), spacing: 18, alignment: .top),
        count: 3
    )
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 24) {
            if items.isEmpty {
                placeholder
            } else {
                ForEach(items) { item in
                    RetroAppCard(metadata: item)
                }
            }
        }
    }
    
    private var placeholder: some View {
        RetroAppCard(metadata: AppDisplayItem(
            kind: .placeholder,
            id: "placeholder",
            title: "No selections yet",
            subtitle: "Tap settings to choose apps",
            applicationToken: nil,
            categoryToken: nil,
            webDomainToken: nil
        ))
    }
}

private struct RetroAppCard: View {
    var metadata: AppDisplayItem
    
    var body: some View {
        iconView
            .frame(width: 72, height: 72)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch metadata.kind {
        case .app:
            if let token = metadata.applicationToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 68))
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(RetroTheme.Palette.highlight.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: RetroTheme.Palette.highlight.opacity(0.3), radius: 10, x: 0, y: 4)
            } else {
                placeholderIcon
            }
        case .category:
            if let token = metadata.categoryToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 60))
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                placeholderIcon
            }
        case .domain:
            if let token = metadata.webDomainToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 60))
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                placeholderIcon
            }
        case .placeholder:
            placeholderIcon
        }
    }
    
    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(RetroTheme.Palette.panelBorder, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
            .frame(width: 72, height: 72)
            .overlay(
                Text("?")
                    .font(RetroTheme.Typography.title(22))
                    .foregroundColor(RetroTheme.Palette.mutedText)
            )
    }
}
