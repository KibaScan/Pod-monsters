# Project: Pod Monsters Concurrency Refactoring

## Architecture
Pod Monsters is a headless Apple-native SDK built targeting iOS 17+. The core components are:
- **GameSession**: The primary coordinator class running on the `@MainActor`. It delegates and coordinates sensor input, environment scanning, fishing states, workout rep scoring, and gamification logic.
- **AirPodsMotionManager**: Wraps `CMHeadphoneMotionManager` to parse raw headphone motion inputs into pitch/yaw calibration deltas, absolute carriage pitch, and stillness tracking. Runs on the `@MainActor`.
- **WorkoutRepRestManager**: Tracks lift set reps and initiates rest capture periods based on rep pacing and durability. Runs on the `@MainActor`.
- **FishingEngine**: A parasympathetic-shift-gated state machine for hands-free RPG capture mechanics. Runs on the `@MainActor`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Concurrency Modernization | Remove `NSLock`, `DispatchQueue.main.sync` from `GameSession.swift`, `WorkoutRepRestManager.swift`, `AirPodsMotionManager.swift` | None | DONE |
| 2 | Gamification Evolution | Integrate `checkEvolution` into `GameSession.swift` loops and write unit tests | M1 | DONE |
| 3 | Anti-Tamper Hashing | Implement SHA-256 verification on saving/loading `GameSessionState` and write unit tests | M1 | DONE |
| 4 | Sensor Throttling & Battery Safeguards | Throttling in `AirPodsMotionManager.swift` + NaN/infinite protection | M1 | DONE |
| 5 | E2E Regression & Verification | Run the full test suite and ensure 100% passing tests | M1, M2, M3, M4 | DONE |

## Interface Contracts
### GameSession ↔ AirPodsMotionManagerDelegate
- `motionManager(_:didUpdateCalibrationDelta:pitchDelta:)`
- `motionManager(_:didUpdateStillnessScore:)`
- `motionManager(_:didUpdateHeadCarriage:)`
All delegate callbacks must fire on `@MainActor` and run cleanly without locks.

### GameSession ↔ Evolution Notifications
- Triggering automatic evolution checks when XP is dripped.
- If evolved, update equipped buddy, save state, and trigger a delegate/notification or custom event representing evolution.

### State Persistence Validation
- File format: SHA-256 signature alongside or embedded in JSON file (e.g. `session.json` + `session.json.sha256` or inside a wrapper dict). Let's use `session.json` + `session.json.sha256` or wrap it to ensure clean separation and security. Let's do `session.json.sha256` in the same directory!

## Code Layout
- `Sources/Core/GameSession.swift`
- `Sources/Core/Monster.swift`
- `Sources/Services/AirPodsMotionManager.swift`
- `Sources/Services/WorkoutRepRestManager.swift`
- `Tests/PodMonstersTests/`
