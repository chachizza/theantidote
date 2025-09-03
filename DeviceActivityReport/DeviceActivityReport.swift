//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//
//  Created by Mark T on 2025-09-02.
//

import DeviceActivity
import SwiftUI

// Main entry point for DeviceActivityReport extension
// Renamed to avoid conflict with framework type
@main
struct AntidoteDeviceActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}
