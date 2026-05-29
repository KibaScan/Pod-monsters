# Pod Monsters Workspace Guidelines

## Overview
Pod Monsters is a native iOS 17+ Swift SDK. This workspace utilizes SPM (Swift Package Manager) for builds, tests, and dependency management.

## Build Commands
To clean the build environment and compile the SDK:
```bash
swift package clean
swift build
```

## Testing Guidelines
To run the standard XCTest suite sequentially:
```bash
swift test
```

### Xcode & Simulator Testing
For local compilation, device emulation, and automated simulator testing:
```bash
xcodebuild test -scheme PodMonsters-Package -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Coding Style
- Target Platform: iOS 17.0+, macOS 14.0+
- Standard library: Apple Foundation, Combine, CoreMotion, CryptoKit.
- Isolation: Standardize UI operations on `@MainActor`.
- Warnings: Clean compilation. Treat warnings as errors where possible.

## Strict Concurrency Complete Recommendations
To fully satisfy modern Swift Concurrency guarantees and prepare the package for Swift 6, compilation should include strict concurrency check configurations:
- Add the `-strict-concurrency=complete` flag to Swift compiler settings.
- Avoid using manual synchronization locks (`NSLock`, `pthread_mutex_t`) or synchronous queue jumps (`DispatchQueue.main.sync`) on `@MainActor` isolated classes.
- Ensure asynchronous tasks crossing actor isolation boundaries are properly marked as `@Sendable` or use isolated context await points.
