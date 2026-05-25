# Pod Monsters — Phase 0 (M5) Code Review Findings

> Handoff doc for the next agent (Gemini / Claude Code / whoever).
> Each item is independently verifiable. File references are explicit.
> Reviewer did not have access to `BiomeScanner.swift` source — see § Verify.

---

## Context

Phase 0 of Pod Monsters: an AirPods Pro 4-based wellness RPG. Stack: Swift native iOS, headless SDK + SwiftUI diagnostic dashboard. Code under review: M5 checkpoint, ~13 Swift files (Models, Services, Views, Tests).

Original prompt promised R1–R6 (monster models, AirPods motion service, biome scanner, fishing engine, workout rep/rest manager, diagnostic dashboard). Reviewer's prompt revisions before launch added R7–R9 (persistence + testability scaffolding, spatial audio emission, familiars + geodes). **R7–R9 were not implemented.** Several items below are these unbuilt promises.

Tests passing as of M5: full coverage on the four named services plus monster/bait models. Coverage is unusually thorough for AI-generated code (concurrent execution, NaN handling, polar coordinate solar math, cache TTL boundaries). The architectural backbone — headless SDK decoupled from UI, dependency injection for testability, state machines for each service — held.

The code is in better shape than the gaps below might suggest. These are the deltas, not a verdict.

---

## Severity Legend

- 🔴 **CRITICAL** — broken behavior, data loss, or feature stub masquerading as implemented
- 🟠 **MAJOR** — design gap from spec, or architectural debt requiring refactor
- 🟡 **MINOR** — code quality, dead code, naming
- 🔵 **VERIFY** — couldn't confirm from materials provided; next agent should check

---

## 🔴 Critical Bugs

### C1. No persistence layer exists

**File:** `GameSession.swift`
**Symptom:** `saveState()` encodes state to `Data`, stores it in the in-memory `lastSavedState` property, and discards the `Data`. `appDidEnterBackground()` calls it. `appWillEnterForeground()` "restores" from that same RAM variable. On cold launch, `lastSavedState` is `nil` and all progress is lost.
**Fix:** Implement SwiftData persistence as specified in prompt R7. Define `@Model` entities for `Monster`, `CapturedMonster`, `BaitInventoryItem`, `GameSettings`. Inject `ModelContainer` via `WindowGroup.modelContainer(for:)`. Replace `lastSavedState` round-trip with `ModelContext.save()`.

### C2. `Monster.checkEvolution()` has three identical branches

**File:** `Monster.swift`
**Symptom:** Zephyr, Basalt, and Lumina all evolve into `"Evolved [Name]"` with +20 to every stat. The `kineticXPWeight` / `forgeXPWeight` / `aetherXPWeight` fields are tracked in `addXP` but never read by `checkEvolution`. Synergy evolution (e.g., Basalt + cross-trained Aether XP → Monk Basalt hybrid) was in the implementation plan, never built.
**Fix:** Define an evolution table per starter, branched on XP weight thresholds. Example: `basalt.checkEvolution()` returns `Monk Basalt` when `aetherXPWeight > 0.30` and `level >= 10`, otherwise standard Titan evolution. Steven should sign off on the table — reviewer can draft if asked.

### C3. `GameSession.releaseBuddy(_ monster:)` is a broken stub

**File:** `GameSession.swift`
**Symptom:** The `monster` parameter is never used. The body adds 500 XP to `equippedBuddy` instead. The method name implies releasing a monster from the party; the behavior is "channel essence." No test covers it.
**Fix:** Decide intent and rebuild. If "channel essence for huge XP" was intended, rename to `channelBuddyEssence()` and drop the parameter. Also note: name collides with `FishingEngine.releaseBuddy()` (which resets fishing state). Rename the fishing one to `cancelLine()`.

### C4. Posture drip conflates Sniff Mode geometry with body posture

**File:** `GameSession.swift`, `motionManager(_:didUpdateCalibrationDelta:pitchDelta:)`
**Symptom:** The calibration delta represents head deviation from a virtual sound source in Sniff Mode. The session interprets pitch delta as "good posture vs slouching." If a user calibrates facing a virtual fish and turns their head to look around during gameplay, pitch deviates because of gameplay, not posture. Posture XP fires inappropriately.
**Fix:** Posture must come from a separate data stream. Either add a dedicated delegate method (`didUpdateHeadCarriage(pitchAngleFromGravity:)`) that ignores Sniff Mode reference frame, or remove the posture drip entirely until a separate posture service exists. The concept doc only ever promised "head carriage" passive XP — never full posture.

### C5. HRV captured but never used in fishing gating

**File:** `FishingEngine.swift`, `updateParasympatheticData(hrv:stillness:)`
**Symptom:** `hrvScore` is stored and never read by any gating logic. Parasympathetic confirmation comes purely from `stillness > 0.95`. Implementation plan said "HRV-gated wait timers that reward true parasympathetic drops rather than pure idle time." A user can sit perfectly still in a stressed state and the engine treats it as zen.
**Fix:** Confirmation should require BOTH `stillness > 0.95` AND `hrv > sessionBaseline + delta`, where `sessionBaseline` is established over the first 30 seconds of the fishing session. Alternative: scope-down honestly — rename `parasympatheticShiftConfirmed` to `stillnessConfirmed`, remove `hrvScore`, and acknowledge stillness-only gating until M-something-later.

### C6. Patience decay defeated by motion stillness callback

**File:** `GameSession.swift`, `motionManager(_:didUpdateStillnessScore:)`
**Symptom:** Stillness samples potentially fire at 60Hz on real AirPods. Each sample calls `fishingEngine.updateParasympatheticData(...)`, which when stillness > 0.95 sets `patienceLevel = 1.0`. The tick-based decay model exercised in tests is overwhelmed in production — patience never depletes as long as the user is reasonably still.
**Fix:** Either debounce stillness updates to ~1Hz before forwarding to the engine, OR split `updateParasympatheticData` so storage and patience-reset are separate concerns — only reset patience on a confirmed transition from "not confirmed" to "confirmed," not on every sample where stillness > 0.95.

### C7. `FishingState.casting` is dead state

**File:** `FishingEngine.swift`, `castLine(bait:)`
**Symptom:** `currentState = .casting` is immediately followed by `currentState = .waiting` on the same call stack. No observer ever sees `.casting`. The enum case exists in `FishingState` but is unreachable.
**Fix:** Either remove the case entirely, or make casting a real transient state with duration (audio cue plays, line travels, after N seconds → `.waiting`). The latter aligns with the design intent of a felt cast moment.

### C8. `@Published` writes off main thread

**Files:** `WorkoutRepRestManager.swift`, `GameSession.swift`
**Symptom:** Both classes use `NSLock` for logic protection but mutate `@Published` properties on whatever thread called the public method. Tests fire from `DispatchQueue.global()` and pass because the assertions read state directly. In production with SwiftUI bindings, the runtime will log `"Publishing changes from background threads is not allowed; make sure to publish values from the main thread"` and may cause UI glitches or crashes under thermal/memory pressure.
**Fix:** Port the `updateOnMainThread` pattern already correctly implemented in `AirPodsMotionManager.swift` to both classes. Alternatively, annotate both classes `@MainActor` and route background-originating calls through `Task { @MainActor in ... }`.

---

## 🟠 Major Design Gaps (Promised in Spec, Not Built)

### D1. Familiars system is half-wired
`equippedBuddy: Monster?` exists on `GameSession`. There is no pre-workout familiar selection gate, no per-workout XP routing summary, no UI affordance for the choice. Tests pass because they don't exercise the loop. Concept doc promised: "equip a monster before a workout, that workout levels that specific monster." Data layer satisfies this; gameplay loop doesn't.
**Build:** A `WorkoutSessionConfig` struct (`familiar: Monster, workoutType: Faction`), a familiar selector view shown at workout start, an XP attribution summary at workout end.

### D2. Geodes (cumulative-effort hatching) entirely absent
No `Geode` model, no hatch trigger anywhere, no in-progress accumulation. This is one of the retention mechanics adopted from Gemini's own original concept pitch.
**Build:** SwiftData `@Model Geode { id; type: GeodeType; requiredEffort: Double; accumulatedEffort: Double; hatchedMonster: Monster? }`. `WorkoutRepRestManager` and `FishingEngine` dispatch effort events. Hatch event when `accumulatedEffort >= requiredEffort`.

### D3. Dex (locked-silhouette gallery) absent
No data model for "discovered but not captured" state. Currently `capturedMonsters: [Monster]` is the only collection.
**Build:** `@Model DexEntry { species: String; discovered: Bool; captured: Bool; firstSeenAt: Date? }`. A gallery view that shows silhouettes for `discovered && !captured` and full art for `captured`.

### D4. Spatial audio emission absent
`AirPodsMotionManager` reads head orientation. Nothing emits directional audio for the user to turn toward. Sniff Mode is therefore half a feature — the listening half exists, the speaking half doesn't.
**Build:** `SpatialAudioService` wrapping `AVAudioEngine` + `PHASE` for 3D-positional audio with a virtual source coordinate. Should expose `emit(source:position:)` and integrate with `BiomeScanner.currentState` for ambient.

### D5. Capture gesture engine absent
Concept doc specifies Apple Watch AssistiveTouch (pinch-flick) as the Phase 0 stand-in for AirPods cam gestures (which don't exist until AP Pro 4 ships). No `CaptureGestureService`, no Watch Connectivity integration. The `simulateGesture(_:)` method on `AirPodsMotionManager` is the entire gesture surface — useful for testing, not for play.
**Build:** `CaptureGestureService` reading from `WCSession` paired with Apple Watch. Detect pinch-flick via Watch's `HKWorkoutSession` motion stream + AssistiveTouch API.

### D6. Capture variety is two monsters total
**File:** `FishingEngine.reelIn()`
**Symptom:** Literal in code: `currentBait == .mindBeads ? "Aqua Spirit" : "Wild Puddle Sprite"`. No biome influence, no rarity, no procedural generation, no catch table. The biome scanner subsystem exists in isolation — it doesn't feed catch decisions.
**Build:** Define `CatchTable: [BiomeType: [Bait: [(species: MonsterSpecies, weight: Double, rarity: Rarity)]]]`. Factor in solar period and tempest state. Reviewer can draft initial table on request.

---

## 🟠 Major Architectural Concerns

### A1. Mock fields baked into production class
`BiomeScanner` carries `mockTime`, `mockOverpassResponse`, `mockWeatherRainy`, `shouldFailNetwork` as instance properties. Acceptable for Phase 0, unacceptable for any release.
**Refactor:** Extract time/weather/network behind protocols (`Clock`, `WeatherProvider`, `BiomeNetworkProvider`). `BiomeNetworkProvider` protocol already exists — extend the pattern to the other two. Construct with real implementations in production, mocks in tests. Remove the `mock*` properties from `BiomeScanner` entirely.

### A2. Concurrency: locks protect logic but not @Published
See C8. Listed here because the underlying pattern (lock the mutation, forget the publish thread) repeats across two files and will likely repeat again if not addressed centrally.

### A3. No `GameConstants.swift`
Tuning constants scattered across files:
- `WorkoutRepRestManager`: 0.5s rep dedup window, 20% durability drop per max-quality rep, 120s set cap, 90s rest cap, 1.0s future-rep tolerance
- `FishingEngine`: 0.05 patience decay per tick, 0.95 stillness threshold for shift confirmation, 6.0 ideal breaths/min, 0.15 tension decrease on perfect breath, 0.25 tension increase on erratic breath, 0.3 initial reel tension
- `Monster`: 100 XP per level, level cap 100, 10 min for evolution, 0.5x XP multiplier for cross-faction
- `BiomeScanner`: 15-min cache TTL

Centralize in `GameConstants.swift` so the game can be tuned without grep-replace across files.

### A4. `CMHeadphoneMotionManager` subclassed for testing
**File:** `MotionTests.swift`, `TestHeadphoneMotionManager: CMHeadphoneMotionManager`
Apple's framework classes are not documented as subclassable. Overriding `isDeviceMotionAvailable`, `isDeviceMotionActive`, `startDeviceMotionUpdates(to:withHandler:)` works today but could break on any iOS release.
**Refactor:** Define `HeadphoneMotionProvider` protocol matching the slice of `CMHeadphoneMotionManager` actually used. Production impl wraps the real class. Mock impl for tests. Inject via `motionManagerInstance`.

### A5. iOS target not visible in materials
No `Package.swift` or `.xcodeproj` in the review materials. Original prompt said iOS 17; reviewer pushed back to 18+. Confirm and document in `Package.swift` minimum platform.

### A6. Pure-faction stat growth wedge
**File:** `Monster.swift`, `addXP` level-up math
A pure-Kinetic Zephyr who only does cardio reaches level 100 with ~1000 speed/agility and starter-level (5) power, hp, focus, special. 40 HP at level 100 = one-shot kill scenarios. Pure mains are punished arbitrarily.
**Fix options:** (a) Grant flat baseline growth on all stats per level (e.g. +2 to each stat regardless of weight, plus +8 weighted), or (b) cap any single XP weight at 0.7 max so some XP always spills to other axes. Steven should pick.

### A7. Spatial cache invalidation absent in `BiomeScanner`
Cache is time-based (15-min TTL) per `testT2_F4_09_CacheExpirationTTL`. Walking 5 km still hits the cache for the original location.
**Fix:** Round coordinates to a geohash grid (~100–250m precision) for the cache key. Optionally also invalidate when `CLLocationManager` reports movement > N meters from cached coord.

### A8. Overpass API rate-limit fragility
Overpass enforces aggressive rate limits and asks heavy consumers to self-host. No retry/backoff visible in test surface. Production usage at scale will 429-storm.
**Fix:** `User-Agent` header (Overpass asks for one identifying the app), exponential backoff on 429 responses, in-flight request coalescing keyed on the spatial cache key. Long-term: migrate to Apple's MapKit POI search (`MKLocalPointsOfInterestRequest`), fully native, no third-party request.

---

## 🟡 Minor / Code Quality

### M1. `BaitType.masterLures.associatedFaction()` arbitrarily returns `.kinetic`
Master Lures are premium catch-anything bait; they should not have a faction at all.
**Fix:** Change return type to `Faction?` and return `nil` for `masterLures`.

### M2. `Bait` struct is dead code
**File:** `Bait.swift`
Only `BaitType` enum is used anywhere in the codebase. The `Bait` struct is never instantiated.
**Fix:** Delete it.

### M3. `MockHealthKitWorkoutBridge` reconstructed every SwiftUI body call
**File:** `WorkoutView.swift`
`bridge` is a computed property that allocates a new bridge on every redraw. Not a bug because the bridge has no real state, but it's a smell.
**Fix:** `@State private var bridge: MockHealthKitWorkoutBridge?` initialized in `.onAppear`.

### M4. Terminology collision: "lure"
`BaitType.spinnerLures` (fishing tackle) is shipped. Concept doc reserves "lure" for spawn modifiers (cadence lure, exertion lure, zen lure). When spawn modifiers ship, the term collides across the codebase.
**Fix:** Rename the spawn-modifier concept now, before it lands. Reviewer recommendation: "beacon" (cadence beacon, exertion beacon, zen beacon). "Signal" and "call" also work. Cheaper to rename a concept that doesn't exist yet than to rename `BaitType.spinnerLures`.

### M5. "buddy" vs "familiar" terminology
Concept doc uses "familiar" throughout. Code uses "buddy" (`equippedBuddy`, `releaseBuddy`, `noBuddyEquipped`). Pick one. Reviewer recommendation: "familiar" — more atmospheric, distinct from generic gaming "buddy" usage. Either is fine, just consistent.

### M6. Logging via `print`
**File:** `AirPodsMotionManager.swift`
Motion errors and fallback notices use `print`. Won't be filterable in Console.app, won't get redacted, will pollute or be stripped depending on build config.
**Fix:** Use `os.Logger` with a per-subsystem category. Example: `private let logger = Logger(subsystem: "com.podmonsters.sdk", category: "AirPodsMotion")`.

### M7. Faction stored alongside `BaitType` rawValue strings
Stat fields (`speed`, `agility`, `power`, `hp`, `focus`, `special`) are individual `Double`s on `Monster`. Workable but rigid — adding a new stat or a stat-modifier system means touching every starter factory and every level-up calculation.
**Consider (not urgent):** `var stats: [Stat: Double]` keyed by an enum. Defer until a stat-modifier system is actually needed.

---

## 🔵 BiomeScanner Verification Checklist

The reviewer did not see `BiomeScanner.swift` source — only its API surface inferred from `BiomeTests.swift`. Once the file is available, verify the following:

1. **Overpass URL hardcoded?** If yes, refactor behind `BiomeNetworkProvider`. Confirm `User-Agent` header is set (Overpass requires one identifying the app).
2. **Retry/backoff on HTTP 429?** Overpass rate-limits aggressively. Need exponential backoff with jitter and a circuit breaker for sustained failure.
3. **In-flight request coalescing?** Test `testT2_F4_04_SimultaneousOverlappingScans` only checks completion, not coalescing. 10 simultaneous identical-coord calls should result in 1 Overpass request, not 10.
4. **Spatial cache key precision.** Is cache keyed on exact `CLLocationCoordinate2D` or a rounded geohash grid (~100–250m)? Exact coords means every GPS jitter is a cache miss.
5. **`@MainActor` isolation status.** `BiomeTests` is annotated `@MainActor`. Is `BiomeScanner` also main-isolated, or does it just happen to work in tests because of the actor context? Affects calls from `GameSession`, which is not main-isolated.
6. **WeatherKit integration real or mocked-only?** Tests only set `mockWeatherRainy`. Verify there's an actual `WeatherService.shared.weather(for:)` code path, not a mock-only branch.
7. **Offline fallback marker on `BiomeState`.** Returns `.neutral` type on network failure. Does the returned state include a flag indicating "degraded result" so callers can distinguish a real neutral biome from a fallback? Add `isOfflineFallback: Bool` if missing.
8. **Mock fields refactor plan.** Confirm migration path to move `mockTime`, `mockOverpassResponse`, `mockWeatherRainy`, `shouldFailNetwork` behind protocol seams (see A1).
9. **Solar geometry math at high latitudes.** Polar tests pass (midnight sun, polar night). Verify implementation uses a real solar position algorithm (NREL SPA, NOAA solar calculator formulas, or similar), not linear interpolation between sunrise/sunset — linear interpolation breaks above ~60° latitude.
10. **Cache key includes more than coordinate?** If cache is purely coordinate-keyed, a cached `greenSpace` will mask a tempest weather change at the same location. Cache key should include `solarPeriod` bucket and `mockWeatherRainy` state, or weather/solar should be looked up fresh outside the cache.

---

## 🔵 Open Questions for Steven

1. **iOS target version locked?** Reviewer recommended 18+. Original prompt said 17. Confirm and document.
2. **Synergy evolution design.** Define the evolution table per starter (Basalt + aetherXPWeight > 0.3 → Monk Basalt, etc.). Reviewer can draft if you want.
3. **HRV gating policy.** Implement real HRV-based parasympathetic confirmation (C5), or scope-down honestly to stillness-only and rename the field?
4. **Posture mechanic future.** Keep "head carriage" passive XP as a real feature with its own service, or cut entirely until AP Pro 4 ships? Currently it's wired wrong (C4) — needs a decision before fixing.
5. **Capture table design.** Define catch tables per biome × bait × solar period × tempest state. Reviewer can draft if you want.
6. **Persistence choice.** SwiftData (recommended for greenfield iOS 17+) vs Core Data vs JSON-in-Documents? Reviewer recommends SwiftData.
7. **Familiar vs buddy.** Pick one name. Lock it.
8. **Lure vs beacon/signal/call.** Pick a name for the spawn-modifier concept. Lock it before the concept lands in code.

---

## Suggested Order for M6

1. **C8** (main-thread `@Published`) — easy, prevents production runtime warnings and possible crashes.
2. **C1 + D1** (persistence + familiars together — they share the data model).
3. **C2** (synergy evolution — high gameplay impact, low code surface).
4. **C3, C4** (broken stubs + posture refactor).
5. **D2** (geodes — retention mechanic, retention matters more than polish at Phase 0).
6. **C5, C6** (HRV + patience — fishing depth).
7. **A1, A3** (mock fields + constants — cleanup before more code lands on top).
8. **D4, D5** (spatial audio + gestures — the second half of Sniff Mode).
9. **D6** (capture variety — once spatial audio lets the user actually hear different things).
10. **D3** (dex — UI feature, last).

---

## Things Done Well (Don't Refactor)

These are working and should be preserved against churn:

- **Headless SDK / SwiftUI decoupling.** `GameSession` is `ObservableObject` and the views observe; no business logic lives in views. Maintain this boundary.
- **State machines for the four services.** `idle → activeSet → restCapture` and `idle → waiting → biting → reeling → captured/snapped`. Clean and testable.
- **`AirPodsMotionManager.updateOnMainThread` pattern.** Port this elsewhere (see C8), don't tear it out here.
- **`BiomeNetworkProvider` protocol seam.** Extend this pattern to other dependencies (A1), don't replace it.
- **Faction naming (Kinetic / Forge / Aether).** Reads better than the concept doc's "Cardio Sprinters / Strength Titans / Zen Spirits." Keep.
- **`WorkoutRepRestManager` date injection for testability.** The `performRep(quality:duration:at:)` signature with injectable `Date` is the right pattern. Keep.
- **`FishingEngine` state-machine + `didSet` line tension clamp.** Defensive, correct. The snap-on-tension-overflow observer is good design.
- **Diagnostic dashboard sliders + mock inputs.** This is the right shape for a developer test harness. Don't put effort into making it pretty; once real gameplay UI lands in M-later, this dashboard stays as a debug-flag-gated tab.
- **Test coverage of edge cases** — NaN inputs, polar coordinates, out-of-order timestamps, future timestamps, concurrent calls. Don't let new code regress this.

---

*Reviewer: Claude (Anthropic). Generated 2026-05-21. Each finding above is independently verifiable from the M5 codebase. Hand this doc to the next agent (Gemini, Claude Code, or human) along with the source.*
