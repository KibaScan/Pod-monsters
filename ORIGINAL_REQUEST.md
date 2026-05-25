# Original User Request

## Initial Request — 2026-05-20T22:59:02-04:00

# Teamwork Project Prompt — Pod Monsters Phase 0 Foundation

> Status: Approved for execution
> Goal: Build a native Swift modular foundation for **Pod Monsters**—a heads-up, hands-free wellness RPG utilizing AirPods head-tracking, HealthKit activity metrics, and an HRV-gated meditation/fishing state machine.
> Working directory: `/Users/stevendiaz/Pod monsters`

## Reference Materials
All architectural details, monster taxonomy, mechanics, and biome definitions are documented in the following files in your working directory. You **must** read them before starting:
- **[pod-monsters-concept.md](file:///Users/stevendiaz/Pod%20monsters/pod-monsters-concept.md)** — Core design document detailing the biomes, factions, and fishing mechanics.
- **[pod-monsters-asset-pipeline.md](file:///Users/stevendiaz/Pod%20monsters/pod-monsters-asset-pipeline.md)** — Technical implementation details and 2D billboard mechanics.

## Guardrails & Integrity Constraints
- **Strict Apple-Native:** The team is strictly prohibited from using third-party libraries, Cocoapods, SPM packages, or non-Apple game engines. The project must rely exclusively on native Apple frameworks (`SwiftUI`, `CoreLocation`, `CoreMotion`, `HealthKit`, `WeatherKit`, `AVFoundation`). Query external APIs (e.g., OpenStreetMap) using standard `URLSession`.
- **Architecture:** The core must be a pure, headless backend/SDK architecture, completely decoupled from the UI to allow for future AR/SpriteKit integrations.

## Requirements

### R1. Core Pod Monsters & Bait Models
Implement the structural definitions for the game's creature taxonomy (Kinetic, Forge, and Aether factions, including starter stats for Zephyr, Basalt, and Lumina, growth calculations, and synergy evolutions) alongside the Bait Economy (Iron Hooks, Spinner Lures, and Mind Beads).

### R2. AirPods Motion & Sniff Mode Service
Wrap CoreMotion's `CMHeadphoneMotionManager` to provide:
- A spatial calibration/alignment math engine ("Sniff Mode") that tracks yaw/pitch deviation from a virtual target coordinate.
- A high-sensitivity micro-movement stillness tracker to score head stillness during meditation or Stillness Lock capture events.

### R3. Biome & Environmental Scanner
Analyze GPS inputs against OpenStreetMap tags (via `URLSession`) for water, green space, urban density, or gym locations. Integrate local solar geometry calculations (dawn, dusk, day, night based on coordinates) and structure WeatherKit indicators for Tempest weather triggers without network blocking.

### R4. Blue Mind Fishing State Machine
Implement the core `FishingEngine` state machine (States: Idle, Casting, Waiting, Biting, Reeling, Captured, Snapped). Incorporate haptic tug triggers, patience levels tied to parasympathetic shifts (mocked HRV data for Phase 0), and the "Tai-Chi Reel" breath-synchronized tension algorithm.

### R5. Workout Rep & Rest Manager
Bridge HealthKit metrics to run the "Shield Crack + Rest Capture" loop, tracking lift set pacing and triggers to initiate rest capture periods safe for hands-free weight lifting.

### R6. Diagnostic / Debug SwiftUI Dashboard
Create a utilitarian, unstyled SwiftUI interface to test and visualize the headless SDK on-device:
- **Sniff Mode View:** A visual compass/radar showing real-time head tracking delta from the AirPods.
- **Biome View:** Text readout of current mock/real GPS, time of day, and parsed OpenStreetMap biome.
- **Fishing View:** Buttons to trigger state changes, sliders to mock HRV/Movement inputs, and a progress bar showing Line Tension.

## Acceptance Criteria

### Component Isolation & Compilation
- [ ] Code is 100% written in Native Swift (targeting iOS 17+).
- [ ] Code compiles cleanly with zero warnings or errors.
- [ ] Business logic is entirely decoupled from the SwiftUI diagnostic views.

### Verification & Testing (`XCTest`)
- [ ] Implement comprehensive `XCTest` unit tests for the core logic.
- [ ] Validate critical mathematical subsystems programmatically (feed mock yaw/pitch data to the Sniff Mode engine and assert correct offset angles; test local sunrise/sunset geometry math).
- [ ] Test the `FishingEngine` (verify state transitions and ensure the line "snaps" if simulated tension thresholds are exceeded).
- [ ] Test Biome manager routing by passing mock coordinate data and asserting the correct parsed biome.

### Functional Verification (UI)
- [ ] The SwiftUI diagnostic dashboard successfully binds to the underlying logic, allowing a developer to physically test the `CMHeadphoneMotionManager` with real AirPods on a physical device.

## Follow-up — 2026-05-21T04:25:54Z

# Teamwork Project Prompt — Pod Monsters M5 Review Adoption

> Status: Approved for execution
> Goal: Implement all fixes, refinements, and feature gaps from the M5 Code Review (C1-C8, A1-A8, D1-D6) to ensure a thread-safe, 100% passing, robust offline-safe headless SDK.
> Working directory: `/Users/stevendiaz/Pod monsters`

## Reference Materials
All architectural details, reviews, and concepts are documented in your working directory. You **must** read them before starting:
- **[pod-monsters-m5-review.md](file:///Users/stevendiaz/Pod%20monsters/pod-monsters-m5-review.md)** — Core Code Review findings to resolve.
- **[pod-monsters-concept.md](file:///Users/stevendiaz/Pod%20monsters/pod-monsters-concept.md)** — Core design document.
- **[pod-monsters-asset-pipeline.md](file:///Users/stevendiaz/Pod%20monsters/pod-monsters-asset-pipeline.md)** — Billboard/asset pipelines.

## Guardrails & Integrity Constraints
- **Strict Apple-Native:** Exclusive reliance on `SwiftUI`, `CoreLocation`, `CoreMotion`, `HealthKit`, `WeatherKit`, `AVFoundation`. Zero third-party packages or SPM dependencies.
- **Pure Headless SDK Boundary:** Business logic and state machine mutations remain 100% decoupled from views, ensuring pure headless operation.

## Requirements

### R1. Thread Safety & Main-Thread Published Isolation (C8)
Port the `updateOnMainThread` pattern using `DispatchQueue.main.sync` to `GameSession`, `WorkoutRepRestManager`, and `FishingEngine` to guarantee all mutations of `@Published` properties are fully serialized to the main thread.

### R2. Native Sandbox File Persistence (C1)
Implement a native JSON serialization/deserialization persistence layer in `GameSession`. Write `GameSessionState` to the physical file `Library/Application Support/PodMonsters/session.json` inside the sandbox, falling back to temporary directories/UserDefaults in tests. Restore session state on app restart and background transitions.

### R3. Synergy Evolution & Adaptive Growth Math (C2, A6)
- Implement species-specific evolution branches in `Monster.swift`:
  * *Zephyr* evolves to *Evolved Zephyr* (if pure kinetic) or *Titan Zephyr* (if kinetic/forge hybrid).
  * *Basalt* evolves to *Evolved Basalt* (if pure forge) or *Monk Basalt* (if forge/aether hybrid).
  * *Lumina* evolves to *Evolved Lumina* (if pure aether) or *Aero Lumina* (if aether/kinetic hybrid).
- Level-up stat calculations must grant `+2` baseline growth to all stats (speed, agility, power, hp, focus, special) plus `+8` weighted based on faction XP weights.

### R4. Release Buddy Removal & HRV Gated Gifting (C3, C5, C6, C7)
- **Release Buddy:** Update `releaseBuddy(_:)` to actually remove the target monster from `capturedMonsters` and channel its essence as 500 XP to the active buddy.
- **HRV Patience Gating:** Set `sessionBaselineHRV` at cast time. Gating requires BOTH `stillnessScore > 0.95` and `hrvScore >= sessionBaselineHRV - 5.0`.
- **Stillness Reset:** Only reset `patienceLevel = 1.0` on the initial `parasympatheticShiftConfirmed` transition from `false` to `true` (resolving the 60Hz loop reset).
- **Casting State:** Make `.casting` a transient state that transitions to `.waiting` on a simulation tick.

### R5. Passive absolute posture drip (C4)
Introduce absolute posture tracking using gravity-relative pitch angle (from the AirPods raw device motion) via a new delegate method `didUpdateHeadCarriage(_:)`, ignoring the calibrated Sniff Mode reference frame. Keep `didUpdateCalibrationDelta` functional for Sniff Mode.

### R6. Game Constants & Biome Catch Table (A3, D6)
- **Game Constants:** Centralize all tuning constants (dedup window, decay, breath rates, thresholds, solar limits, cache TTL) in `GameConstants.swift`.
- **Catch Table:** Introduce a structured dictionary mapping biomes and baits to procedural catch results (e.g. `Aqua Spirit` in water, `Leaf Sprite` in green spaces, `Street Racer` in urban, `Concrete Golem` in gyms) instead of hardcoded strings.

## Acceptance Criteria

### Thread Safety & Concurrency
- [ ] Running the sequential test suite (`swift test`) does not crash, freeze, or terminate with exit code 6 (SIGABRT).
- [ ] Concurrent dispatches from global queues safely execute mutations on the main thread and pass all assertions.

### Functional Specifications
- [ ] Cold launch restores previously saved session state from local file storage.
- [ ] Posture XP drips only based on absolute gravity tilt; calibration deviations do not fire posture XP drips.
- [ ] Patience decays as expected even when stillness remains continuously above 0.95.
- [ ] Starters evolve into correct hybrid species if cross-trained.
- [ ] Level-up stats grant baseline stats avoiding the 40 HP lock.
- [ ] Released buddies are completely purged from the Captured Monsters list.
- [ ] Capturing monsters produces variety based on the active biome and bait.

## Follow-up — 2026-05-21T04:36:29Z

From: main agent (5be9fdb6-57d4-400f-963c-f8631e13966a)
Message:
"Hi! I have successfully verified Milestone 2. Both sequential (`swift test`) and parallel (`swift test --parallel`) runs now pass 100% cleanly with 0 crashes. I resolved the remaining transient sequential daemon conflicts by introducing an automatic mock fallback in `AirPodsMotionManager` when executing within `XCTestCase`!

Please proceed with Milestone 2 (Native Sandbox File Persistence) and advance the implementation plan. Let me know when you have a status report or when Milestone 2 is complete."

## Follow-up — 2026-05-23T03:08:54Z

Refactor the Pod Monsters Phase 0 codebase to eliminate redundant thread locks, modernize concurrency isolation with Swift Concurrency `@MainActor`, integrate missing gamification evolution checks, and implement secure state persistence validation.

Working directory: `/Users/stevendiaz/Pod monsters`
Integrity mode: development

## Requirements

### R1. Concurrency Modernization & Thread Lock Removal
Refactor [GameSession.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Core/GameSession.swift), [AirPodsMotionManager.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Services/AirPodsMotionManager.swift), and [WorkoutRepRestManager.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Services/WorkoutRepRestManager.swift) to:
- Remove all manual synchronization locks (`NSLock`, `inventoryLock`).
- Standardize thread dispatching exclusively on native Swift Concurrency `@MainActor` isolation.
- Eliminate legacy GCD synchronous main thread calls (`DispatchQueue.main.sync`, `updateOnMainThread` using `sync`) to prevent deadlock conditions.
- Safe-unwrap or securely fallback from implicit forced unwraps (`!`) in all manager files.

### R2. Core Gamification Evolution Integration
Integrate the existing `checkEvolution()` mechanism from [Monster.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Core/Monster.swift) into the [GameSession.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Core/GameSession.swift) game loop:
- Whenever a monster earns XP or increments a level inside `GameSession`, evaluate `checkEvolution()`.
- If an evolution occurs, update the buddy in the state, persist the changes, and trigger a delegate/notification event representing the evolution.
- Write new unit test cases covering this automatic evolution flow.

### R3. Anti-Tamper State Persistence Hashing
Add basic tamper-resistance protection to the state serialization loop inside [GameSession.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Core/GameSession.swift):
- Generate a SHA-256 validation signature of the serializable JSON state structure.
- Store this signature securely or alongside the JSON file, and verify it on cold boot loading.
- If the signature does not match (representing a manual user save-file hack or file corruption), reject the load or throw a validation error.
- Write a unit test that verifies modified JSON state files fail validation checks properly.

### R4. Sensor Frequency Throttling & Battery Safeguards
Enhance [AirPodsMotionManager.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Services/AirPodsMotionManager.swift) with rate-limiting constraints:
- Implement a configurable sample throttle (e.g. `motionSampleInterval: TimeInterval`) so raw incoming motion updates from CMDeviceMotion are throttled before processing or calling the delegate.
- Protect all math functions against unexpected `NaN` or `.infinite` hardware inputs by returning safe default values.

## Acceptance Criteria

### Threading & Compilation Integrity
- [ ] No compilation warnings or errors exist.
- [ ] All occurrences of `NSLock` and `DispatchQueue.main.sync` are completely removed from [GameSession.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Core/GameSession.swift) and [WorkoutRepRestManager.swift](file:///Users/stevendiaz/Pod%20monsters/Sources/Services/WorkoutRepRestManager.swift).
- [ ] The codebase builds successfully via `swift build`.

### Core Loop & Evolution Integrity
- [ ] The evolution flow triggers automatically upon leveling past Threshold 10 when XP is dripped.
- [ ] Swapping buddies or driping XP works seamlessly.

### Verification & Test Suite Passing
- [ ] Running `swift test` executes successfully.
- [ ] The existing test suites pass 100% cleanly without errors.
- [ ] New unit tests verifying the evolution triggers and file tamper protection pass successfully.

