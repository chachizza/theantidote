# Project Overview

This is a SwiftUI application for iOS that helps users manage their screen time. It uses Apple's Screen Time APIs to set limits on selected applications and provides challenges to unlock them. The project is written in Swift and follows the MVVM architecture.

The application consists of a main app and several extensions:
*   **DeviceActivityMonitor:** Monitors app usage in the background.
*   **DeviceActivityReport:** Provides a report of device activity.
*   **ManagedSettings:** Shields apps when their time limit is reached.
*   **SheildConfig:** Configures the shield that is displayed when an app is blocked.

# Building and Running

The project can be built and run using Xcode. The `README.md` file provides detailed instructions for setting up the project, including enabling the necessary entitlements and configuring app groups.

## Build Commands

*   **Build for simulator:**
    ```bash
    xcodebuild -scheme Antidote -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'
    ```
*   **Build for device:**
    ```bash
    xcodebuild -scheme Antidote -configuration Release -destination 'generic/platform=iOS'
    ```

## Testing Commands

The project uses the Swift Testing framework.

*   **Run all tests:**
    ```bash
    xcodebuild test -scheme Antidote -destination 'platform=iOS Simulator,name=iPhone 15'
    ```
*   **Run unit tests:**
    ```bash
    xcodebuild test -scheme Antidote -only-testing:AntidoteTests
    ```
*   **Run UI tests:**
    ```bash
    xcodebuild test -scheme Antidote -only-testing:AntidoteUITests
    ```

## Common Xcode Commands

*   **List available schemes and configurations:**
    ```bash
    xcodebuild -list
    ```
*   **Clean build folder:**
    ```bash
    xcodebuild clean -scheme Antidote
    ```

# Development Conventions

The codebase is well-structured and follows standard Swift conventions. The MVVM architecture is used to separate the application's logic from its user interface.

*   **Models:** Data structures for the application, such as `AppSettings` and `ChallengeState`.
*   **Views:** SwiftUI views that make up the user interface.
*   **Managers:** Classes that handle business logic, such as `AuthenticationManager`, `StorageManager`, and `BypassManager`.

## Key Files

*   `Antidote/AntidoteApp.swift`: Main app entry point.
*   `Antidote/ContentView.swift`: Primary view.
*   `Antidote/Views/DashboardView.swift`: The main dashboard view.
*   `Antidote/Managers/`: Directory containing the business logic for the application.
*   `AntidoteTests/AntidoteTests.swift`: Unit tests.
*   `AntidoteUITests/`: UI tests.

The project also includes a `TESTING_GUIDE.md` file, which provides additional information on testing the application.