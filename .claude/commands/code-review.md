Perform a comprehensive code review of the given Pull Request targeting the Pod Monsters SDK. Follow this strict checklist, focusing on high-signal Swift Concurrency safety and robust AirPods tracking logic:

1. **Swift Concurrency & Actor Isolation Checklist:**
   - **`@MainActor` Compliance**: Ensure all classes managing UI-bound or stateful operations (`GameSession`, `AirPodsMotionManager`, `WorkoutRepRestManager`, `FishingEngine`) are properly decorated with `@MainActor` to isolate their operations.
   - **No Manual Synchronization Locks**: Verify that there are absolutely zero usages of legacy synchronous locks like `NSLock`, `pthread_mutex_t`, or queue jumps like `DispatchQueue.main.sync`. Such synchronization constructs must be replaced entirely with Swift Cooperative Concurrency (async/await, Task, `@MainActor`).
   - **Sendable Conformances**: Verify that any data models or state payloads crossing concurrency/actor boundaries conform to `@Sendable` or are immutable structs.
   - **Background Thread Safety**: Check that no synchronous main actor-isolated methods are called from background thread queues (such as `DispatchQueue.global().async`) without being properly awaited or wrapped in a `@MainActor` Task.

2. **AirPods Motion Safety & Throttling Checklist:**
   - **Motion Throttling**: Confirm that `CMHeadphoneMotionManager` streams are throttled via an explicit `motionSampleInterval: TimeInterval` parameter to conserve device battery.
   - **Math & Numeric Safety**: Ensure attitude yaw/pitch/roll calibration delta calculations include protection against `NaN` or `infinity` and are safely wrapped within the `[-180, 180]` sphere boundaries.
   - **Preview Agent Interception**: Confirm that instantiations of `CMHeadphoneMotionManager` detect if they are running inside Xcode Canvas Previews (`ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"`) and dynamically substitute a safe, crash-free mock headphone provider.

3. **Persistence Integrity Checklist:**
   - **SHA-256 Anti-Tamper Verification**: Ensure all auto-saving state operations write a secure validation signature to a sibling `session.json.sha256` file, and verify this signature on cold boot loads.

4. **Review Mechanics:**
   - Audit changes in parallel. Focus only on high-signal compilation safety, logic correctness, and explicit `GEMINI.md` violations.
   - Ignore subjective style differences, minor nitpicks, or issues that would be flagged by a local compiler. Only comment on verified bugs or architecture regressions.
