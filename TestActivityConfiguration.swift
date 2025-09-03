import DeviceActivity
import FamilyControls

// Test configuration for device activity monitoring
struct TestActivityConfiguration {
    static func createTestActivity() -> DeviceActivityName {
        return DeviceActivityName("testActivity")
    }
    
    static func createTestEvent() -> DeviceActivityEvent {
        // Create a simple event that triggers after 1 minute
        return DeviceActivityEvent(
            applications: [],
            categories: [],
            threshold: DateComponents(minute: 1)
        )
    }
    
    static func createTestSchedule() -> DeviceActivitySchedule {
        return DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true,
            warningTime: DateComponents(minute: 1)
        )
    }
    
    static func testMonitoringSetup() {
        let activityName = createTestActivity()
        let event = createTestEvent()
        let schedule = createTestSchedule()
        
        do {
            try DeviceActivityMonitor.shared.startMonitoring(activityName, during: schedule)
            try DeviceActivityMonitor.shared.startMonitoring(.init("testEvent"), during: event)
            print("✅ Test monitoring setup complete")
        } catch {
            print("❌ Error setting up test monitoring: \(error)")
        }
    }
}