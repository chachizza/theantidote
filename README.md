# The Antidote

A SwiftUI app that limits time on user-selected social apps using Apple's Screen Time APIs. Built with FamilyControls, DeviceActivity, and ManagedSettings frameworks.

## Features

- **App Usage Limits**: Set daily time limits for specific apps or categories
- **Mindful Challenges**: Complete challenges (Stroop, Math, Trivia, Breath) to unlock apps
- **Smart Notifications**: Get warnings before hitting limits and alerts when blocked
- **Secure Settings**: Face ID/PIN authentication for settings access
- **Bypass System**: Temporary 5-minute access with usage caps (2 passes/day, 10-min lockout)
- **Clean UI**: Accessibility-friendly design with single accent color

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **MVVM**: Model-View-ViewModel architecture
- **App Groups**: Shared data container for persistence
- **Extensions**: DeviceActivityMonitor and ManagedSettings extensions

## Setup Instructions

### 1. Family Controls Entitlement

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to Certificates, Identifiers & Profiles
3. Select your App ID
4. Enable "Family Controls" capability
5. Download and install the updated provisioning profile

### 2. App Group Configuration

1. In Xcode, go to Signing & Capabilities
2. Add "App Groups" capability
3. Create a new App Group with identifier: `group.com.yourcompany.antidote`
4. Update all targets to use the same App Group

### 3. Extension Setup

#### DeviceActivityMonitor Extension
1. Add new target: File → New → Target → Device Activity Monitor Extension
2. Name it "DeviceActivityMonitor"
3. Add to App Group capability
4. Copy `DeviceActivityMonitor.swift` to the extension

#### ManagedSettings Extension
1. Add new target: File → New → Target → Managed Settings Extension
2. Name it "ManagedSettings"
3. Add to App Group capability
4. Copy `ManagedSettingsExtension.swift` to the extension

### 4. Required Capabilities

Add these capabilities to your main app target:
- Family Controls
- App Groups
- Local Authentication (Face ID/PIN)
- User Notifications

### 5. Info.plist Updates

Add these keys to your main app's Info.plist:

```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to secure your settings</string>

<key>NSUserNotificationsUsageDescription</key>
<string>We use notifications to alert you about app limits</string>
```

### 6. URL Scheme

Add URL scheme for deep linking:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>antidote</string>
        </array>
    </dict>
</array>
```

## App Review Notes

### Entitlement Justification
The FamilyControls entitlement is required to:
- Monitor app usage time for selected apps
- Block access to apps when daily limits are reached
- Provide users with mindful challenges to unlock apps
- Promote healthy digital habits

### Privacy Policy
The app:
- Only monitors apps explicitly selected by the user
- Stores all data locally in App Groups
- Does not transmit usage data to external servers
- Respects user privacy and provides full control

### User Experience
- Clear onboarding explaining permissions
- Transparent about which apps are being monitored
- Easy to modify or remove app selections
- Educational approach to digital wellness

## Development Commands

### Build and Run
```bash
# Build for simulator
xcodebuild -scheme Antidote -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for device
xcodebuild -scheme Antidote -configuration Release -destination 'generic/platform=iOS'

# Run tests
xcodebuild test -scheme Antidote -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing
- Unit tests: `xcodebuild test -scheme Antidote -only-testing:AntidoteTests`
- UI tests: `xcodebuild test -scheme Antidote -only-testing:AntidoteUITests`

## File Structure

```
Antidote/
├── Models/
│   ├── AppSettings.swift          # User preferences and settings
│   └── ChallengeState.swift       # Challenge progress tracking
├── Managers/
│   ├── StorageManager.swift       # App Group data persistence
│   ├── AuthorizationManager.swift # FamilyControls authorization
│   ├── AuthenticationManager.swift # Face ID/PIN authentication
│   ├── BypassManager.swift        # Temporary access management
│   └── NotificationManager.swift  # Local notifications
├── Views/
│   ├── ContentView.swift          # Main app entry point
│   ├── DashboardView.swift        # Main dashboard
│   ├── SettingsView.swift         # Settings configuration
│   ├── ChallengeSelectionView.swift # Challenge type selection
│   ├── StroopChallengeView.swift  # Stroop test challenges
│   ├── MathChallengeView.swift    # Math problem challenges
│   ├── TriviaChallengeView.swift  # Trivia challenges (TODO)
│   └── BreathChallengeView.swift  # Breathing exercises (TODO)
├── Extensions/
│   ├── DeviceActivityMonitor/     # Background monitoring
│   └── ManagedSettings/           # App shielding
└── Supporting Files/
    ├── Antidote.entitlements      # Required entitlements
    └── Info.plist                 # App configuration
```

## Usage Flow

1. **First Launch**: Onboarding with permission requests
2. **Setup**: Select apps and set daily limits
3. **Monitoring**: Automatic background tracking
4. **Limit Reached**: Apps blocked with challenge prompt
5. **Challenge**: Complete mindful challenge for temporary access
6. **Reset**: Daily limits reset at midnight

## TODO Items

- [ ] Complete Trivia challenge implementation
- [ ] Complete Breath challenge implementation
- [ ] Add more sophisticated usage analytics
- [ ] Implement cloud sync for settings
- [ ] Add widget for quick status view
- [ ] Implement family sharing features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions:
- Create an issue on GitHub
- Check the troubleshooting guide
- Review Apple's Screen Time API documentation