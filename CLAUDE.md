# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a **Swift iOS application** built with **SwiftUI** as the primary UI framework. The project is structured as a standard Xcode iOS app with unit and UI tests.

## Architecture
- **SwiftUI-based**: Uses modern declarative UI framework
- **MVVM Architecture**: Standard SwiftUI pattern with Views, ViewModels, and Models
- **Testing**: Uses the new Swift Testing framework (`@Test` annotations)
- **Standard Xcode Structure**: Follows Apple's recommended app structure

## Key Files
- `Antidote/AntidoteApp.swift:11` - Main app entry point with `@main` annotation
- `Antidote/ContentView.swift:10` - Primary view displaying "Hello, world!"
- `AntidoteTests/AntidoteTests.swift:11` - Unit tests using Swift Testing framework
- `AntidoteUITests/` - UI testing suite

## Build & Development Commands

### Building
```bash
# Build for simulator
xcodebuild -scheme Antidote -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for release
xcodebuild -scheme Antidote -configuration Release

# Build and run tests
xcodebuild test -scheme Antidote -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme Antidote -only-testing:AntidoteTests

# Run UI tests
xcodebuild test -scheme Antidote -only-testing:AntidoteUITests

# Run all tests
xcodebuild test -scheme Antidote
```

### Common Xcode Commands
```bash
# List available schemes and configurations
xcodebuild -list

# Clean build folder
xcodebuild clean -scheme Antidote

# Build without running
xcodebuild build -scheme Antidote
```

## Development Environment
- **Platform**: iOS
- **Framework**: SwiftUI
- **Testing**: Swift Testing framework (new in Swift 5.9+)
- **Build System**: Xcode build system
- **Language**: Swift 5.x

## Project Structure
```
Antidote/                 # Main app source
├── Assets.xcassets/      # App icons and images
├── ContentView.swift     # Main view
└── AntidoteApp.swift     # App entry point

AntidoteTests/            # Unit tests
└── AntidoteTests.swift

AntidoteUITests/          # UI tests
├── AntidoteUITests.swift
└── AntidoteUITestsLaunchTests.swift
```

## Important Notes
- Uses Swift Testing framework (not XCTest) - look for `@Test` annotations
- SwiftUI-based app with standard MVVM patterns
- No external dependencies in current state
- Standard Xcode project structure for iOS development