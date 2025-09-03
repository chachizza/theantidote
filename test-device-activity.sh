#!/bin/bash

# Device Activity Extension Testing Script
# Run this script to set up testing environment

echo "🚀 Setting up Device Activity Extension Testing..."

# 1. Check if simulator is available
echo "📱 Checking available simulators..."
SIMULATOR=$(xcrun simctl list devices | grep "iPhone 16" | head -1 | sed 's/.*iPhone 16.*(\([A-Z0-9\-]*\)).*/\1/')

if [ -z "$SIMULATOR" ]; then
    echo "❌ iPhone 16 simulator not found. Available simulators:"
    xcrun simctl list devices | grep "iPhone"
    exit 1
fi

echo "✅ Found iPhone 16 simulator: $SIMULATOR"

# 2. Boot the simulator
echo "🔌 Booting simulator..."
xcrun simctl boot "$SIMULATOR" 2>/dev/null || echo "Simulator already booted"

# 3. Install the app (if built)
APP_PATH="./Build/Products/Debug-iphonesimulator/Antidote.app"
if [ -d "$APP_PATH" ]; then
    echo "📦 Installing app to simulator..."
    xcrun simctl install "$SIMULATOR" "$APP_PATH"
else
    echo "⚠️  App not found at $APP_PATH"
    echo "   Build the app first with: xcodebuild -scheme Antidote -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build"
fi

# 4. Create test configuration
echo "⚙️  Creating test configuration..."
cat > /tmp/test-activity-config.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>testActivity</key>
    <dict>
        <key>applications</key>
        <array>
            <string>com.apple.mobilesafari</string>
        </array>
        <key>threshold</key>
        <string>1m</string>
    </dict>
</dict>
</plist>
EOF

# 5. Launch Screen Time setup
echo "📊 Opening Screen Time in simulator..."
xcrun simctl launch "$SIMULATOR" com.apple.Preferences

echo ""
echo "✅ Setup Complete! Next steps:"
echo ""
echo "1. In the simulator, go to Settings → Screen Time"
echo "2. Tap 'Turn On Screen Time'"
echo "3. Set up App Limits for Safari (1 minute limit)"
echo "4. Use Safari for 1+ minutes to trigger the extension"
echo ""
echo "📝 To view extension logs:"
echo "   xcrun simctl spawn booted log show --predicate 'process == \"DeviceActivityMonitor\"' --info"
echo ""
echo "🔍 To test extension directly:"
echo "   xcodebuild -scheme DeviceActivityMonitor -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' test"