//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by Mark T on 2025-09-02.
//

import DeviceActivity

// The extension entry point - make sure this class name matches NSExtensionPrincipalClass in Info.plist
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Handle the start of the interval.
        print("Interval started for activity: \(activity.rawValue)")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Handle the end of the interval.
        print("Interval ended for activity: \(activity.rawValue)")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Handle the event reaching its threshold.
        print("Event \(event.rawValue) reached threshold for activity: \(activity.rawValue)")
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Handle the warning before the interval starts.
        print("Warning: interval will start for activity: \(activity.rawValue)")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // Handle the warning before the interval ends.
        print("Warning: interval will end for activity: \(activity.rawValue)")
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        // Handle the warning before the event reaches its threshold.
        print("Warning: event \(event.rawValue) will reach threshold for activity: \(activity.rawValue)")
    }
}
