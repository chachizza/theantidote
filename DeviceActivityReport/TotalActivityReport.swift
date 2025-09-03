//
//  TotalActivityReport.swift
//  DeviceActivityReport
//
//  Created by Mark T on 2025-09-02.
//

import DeviceActivity
import SwiftUI

// Extension for DeviceActivityReport.Context
extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    
    let content: (String) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        
        var totalDuration: TimeInterval = 0
        
        // Process the activity data correctly
        for await activityData in data {
            // Sum up durations from activity segments
            let segments = activityData.activitySegments
            for await segment in segments {
                totalDuration += segment.totalActivityDuration
            }
        }
        
        return formatter.string(from: totalDuration) ?? "No activity"
    }
}
