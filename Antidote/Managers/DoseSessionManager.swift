//
//  DoseSessionManager.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

final class DoseSessionManager: ObservableObject {
    static let shared = DoseSessionManager()
    
    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedStore = ManagedSettingsStore()
    private var pollingTimer: Timer?
    private var appUsageStartTime: Date?
    
    private init() {}
    
    func startSession(settings: AppSettings) {
        let selection = settings.selectedApps
        guard !selection.applicationTokens.isEmpty else {
            print("⚠️ DoseSessionManager: No apps selected, skipping monitoring")
            return
        }
        
        stopMonitoring()
        startDeviceActivityMonitoring(selection: selection, minutes: settings.dailyLimitMinutes)
        startManualPolling()
    }
    
    func stopSession() {
        stopMonitoring()
        clearShield()
    }
    
    func applyImmediateShield(selection: FamilyActivitySelection) {
        guard !selection.applicationTokens.isEmpty else { return }
        
        managedStore.shield.applications = selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            managedStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        
        print("🛡️ DoseSessionManager: Shield applied to \(selection.applicationTokens.count) apps")
    }
    
    func clearShield() {
        managedStore.shield.applications = nil
        managedStore.shield.applicationCategories = nil
        print("🛡️ DoseSessionManager: Shields cleared")
    }
    
    private func stopMonitoring() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        appUsageStartTime = nil
        
        deviceActivityCenter.stopMonitoring([
            .daily,
            DeviceActivityName("antidote.daily.monitoring"),
            DeviceActivityName("antidote.current.session")
        ])
    }
    
    private func startDeviceActivityMonitoring(selection: FamilyActivitySelection, minutes: Int) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }
        
        let startComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startOfDay)
        let endComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endOfDay)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: startComps,
            intervalEnd: endComps,
            repeats: true
        )
        
        let thresholdComps = DateComponents(minute: max(1, minutes))
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: thresholdComps
        )
        
        do {
            try deviceActivityCenter.startMonitoring(
                DeviceActivityName("antidote.daily.monitoring"),
                during: schedule,
                events: [.timeLimitReached: event]
            )
            print("📡 DoseSessionManager: DeviceActivity monitoring started")
        } catch {
            print("❌ DoseSessionManager: Failed to start monitoring \(error)")
        }
    }
    
    private func startManualPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkAppUsageManually()
        }
    }
    
    private func checkAppUsageManually() {
        guard let foregroundApp = currentForegroundAppBundleId() else { return }
        
        let settings = AppSettings.load()
        let selection = settings.selectedApps
        let minutes = settings.dailyLimitMinutes
        
        let isMonitoredApp = bundle(foregroundApp, matches: selection)
        
        if isMonitoredApp {
            if appUsageStartTime == nil {
                appUsageStartTime = Date()
            } else if let start = appUsageStartTime {
                let usageTime = Date().timeIntervalSince(start)
                let limit = TimeInterval(minutes * 60)
                if usageTime >= limit {
                    applyImmediateShield(selection: selection)
                    appUsageStartTime = nil
                }
            }
        } else {
            appUsageStartTime = nil
        }
    }
    
    private func currentForegroundAppBundleId() -> String? {
        // Simplified assumption for iOS limitations.
        return "com.apple.mobilesafari"
    }
    
    private func bundle(_ identifier: String, matches selection: FamilyActivitySelection) -> Bool {
        if identifier == "com.apple.mobilesafari" {
            return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
        }
        return false
    }
}
