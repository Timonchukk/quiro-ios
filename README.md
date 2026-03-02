# Qurio iOS App

AI-powered learning assistant for iOS — mirrors the Android Qurio app.

## Requirements

- **Xcode 15+**
- **iOS 16.0+** (SwiftData requires iOS 17; CoreData fallback provided for iOS 16)
- **Swift 5.9+**
- **macOS Sonoma 14+** (for development)

## Setup

1. Open `QurioIOSApp.xcodeproj` in Xcode (or create a new Xcode project and add the `QurioIOSApp/` source folder).
2. Configure your development team and bundle identifier.
3. Set the API base URL in `QurioIOSApp/Config.swift`:
   ```swift
   static let serverBaseURL = "https://your-server.com"
   ```
4. For Google Sign-In, add your `GoogleService-Info.plist` to the project.
5. For StoreKit, configure product IDs in App Store Connect and update `InAppPurchaseService.swift`.
6. Build and run on a simulator or device.

## Architecture

- **Pattern**: MVVM + Repository
- **UI**: SwiftUI with liquid glass aesthetic
- **Networking**: URLSession
- **Storage**: UserDefaults + Keychain (tokens) + SwiftData/CoreData (history)
- **Subscriptions**: StoreKit 2
- **Screen Capture**: ReplayKit Broadcast Upload Extension

## Project Structure

```
QurioIOSApp/
├── QurioApp.swift              # App entry point
├── ContentView.swift           # Root navigation
├── Config.swift                # Server URL, constants
├── Models/                     # Data models
├── Services/                   # Network, Keychain, StoreKit, ReplayKit
├── Helpers/                    # RateLimiter, glass views, math formatter
├── Repositories/               # Business logic layer
├── Features/                   # UI features
│   ├── Auth/
│   ├── Onboarding/
│   ├── Main/
│   │   ├── AiHub/
│   │   ├── Progress/
│   │   ├── History/
│   │   └── Profile/
│   ├── Overlay/
│   ├── Test/
│   └── Admin/
└── Theme/                      # Colors, typography, glass components
```

## Server

The app communicates with the existing Node.js/Express backend. Ensure the server is running and accessible at the configured base URL.

## ReplayKit Broadcast Extension

To enable screen capture outside the app:
1. Add a new "Broadcast Upload Extension" target in Xcode.
2. Copy `BroadcastUploadExtension/SampleHandler.swift` into the new target.
3. Configure App Groups to share data between the main app and extension.
4. The extension uses `RPBroadcastSampleHandler` to capture screen frames.
