# Device Activity Extension Testing Guide

## Quick Setup (3 minutes)

### 1. Run the Setup Script
```bash
./test-device-activity.sh
```

### 2. Manual Steps (Required)
1. **In the simulator that opens:**
   - Go to **Settings → Screen Time**
   - Tap **Turn On Screen Time**
   - Tap **Continue** → **This is My iPhone**

2. **Set up test limits:**
   - Go to **Settings → Screen Time → App Limits**
   - Tap **Add Limit**
   - Select **Safari**
   - Set limit to **1 minute**
   - Tap **Add**

### 3. Test the Extension
1. **Open Safari** in the simulator
2. **Browse for 1+ minutes**
3. **Check extension logs**:
   ```bash
   # Terminal command to view logs
   xcrun simctl spawn booted log show --predicate 'process == "DeviceActivityMonitor"' --info --last 1m
   ```

## Detailed Testing Methods

### Method A: Direct Extension Testing
1. **In Xcode:**
   - Select **DeviceActivityMonitor** scheme
   - Choose **iPhone 16** as destination
   - Press **⌘R** to run

2. **Check console output** in Xcode

### Method B: Main App Testing
1. **Build and run** the main Antidote app
2. **Follow the Screen Time setup** above
3. **Trigger events** by using apps with limits

### Method C: Automated Testing
```bash
# Build everything
xcodebuild -scheme Antidote -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme DeviceActivityMonitor -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build

# Install app
xcrun simctl install booted Build/Products/Debug-iphonesimulator/Antidote.app

# View real-time logs
xcrun simctl spawn booted log stream --predicate 'process == "DeviceActivityMonitor"' --info
```

## Expected Results

### When Extension Works:
```
Interval started for activity: testActivity
Event testEvent reached threshold for activity: testActivity
Interval ended for activity: testActivity
```

### When Extension Fails:
```
# No logs appear, check:
# 1. Screen Time is enabled
# 2. App limits are set
# 3. Extension is properly signed
# 4. Simulator is iOS 16+ (required for DeviceActivity)
```

## Troubleshooting

### Common Issues:
1. **No logs appear**
   - Solution: Ensure Screen Time is enabled in simulator
   - Check: Settings → Screen Time → Turn On Screen Time

2. **Extension not triggering**
   - Solution: Set up App Limits for specific apps
   - Check: Settings → Screen Time → App Limits → Add Safari (1 min)

3. **Build failures**
   - Solution: Clean build folder (⌘⇧K)
   - Check: All entitlements are correct

### Quick Debug Commands:
```bash
# Check if extension is installed
xcrun simctl listapps booted | grep Antidote

# View extension logs
xcrun simctl spawn booted log show --predicate 'subsystem == "com.yourcompany.antidote"' --info

# Reset simulator if needed
xcrun simctl erase "iPhone 16"
```

## Testing Checklist

- [ ] Extension builds without errors
- [ ] App installs on simulator
- [ ] Screen Time is enabled
- [ ] App limits are configured
- [ ] Extension logs appear when limits are exceeded
- [ ] All override methods are being called

## Time Estimates
- **Initial setup**: 5 minutes
- **Subsequent tests**: 1-2 minutes each
- **Full verification**: 10 minutes (waiting for events to trigger)

## Next Steps
After confirming the extension works:
1. Add actual business logic to the extension
2. Test with real app data
3. Test on physical device (requires developer account)