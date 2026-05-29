# Pod Monsters — Phase A Agent Prompts

> Format matches your `ORIGINAL_REQUEST.md` teamwork prompts. Paste the body after the run command.
>
> **RUN MODE — every milestone here runs under `/goal`, NOT `/teamwork-preview`.**
> `/goal` is a single coordinator that can spawn *background* research/audit subagents while it owns the
> files. These are all new modules *inside* the existing SDK; a `/teamwork-preview` peer squad
> (Developer/Tester/Auditor editing concurrently) fights over files in a tightly-coupled Swift package.
> Reserve `/teamwork-preview` for genuinely greenfield standalone projects.
>
> **Builder model:** Gemini 3.5 Flash (High).
> **Reviewer (separate agent, the `/code-review` gate):** Claude Opus 4.6 (Thinking) — the independent
> auditor `/goal` won't run on itself.
> **Working directory:** `/Users/stevendiaz/Pod monsters` · **Integrity mode:** development
>
> **ORDER:** M-A0 solo (smoke test) → M-A0.5 Podmon rename (solo) → M-A1 → M-A2 → parallel wave
> [M-A3, M-A4, M-A5] in git worktrees (see `docs/WORKFLOW.md`). All gates per `docs/WORKFLOW.md`.
>
> **NAMING:** after M-A0.5 the creature type is `Podmon` (was `Monster`). Where any prompt below says
> `Monster` / `Monster.swift` / "familiar", read `Podmon` / `Podmon.swift` / "Podmon".

---

## M-A0 — Pipeline smoke test: FishingEngine concurrency cleanup   ·   run with `/goal`

```
# Teamwork Project Prompt — M-A0: FishingEngine Concurrency Cleanup

> Goal: Remove the banned synchronous main-thread pattern from FishingEngine and rely on
> @MainActor isolation, with ZERO behavioral change. Pipeline smoke test — run solo to validate
> the build → review → merge loop before scaling to parallel agents.
> Working directory: /Users/stevendiaz/Pod monsters
> Integrity mode: development

## Reference Materials (read first)
- GEMINI.md — build/test/concurrency rules.
- docs/DECISIONS.md — D-01 (Concurrency Isolation / Main Actor).
- ROADMAP.md — milestone M-A0 and the merge gates.
- skills/code-review/SKILL.md — the concurrency checklist this will be reviewed against.

## Guardrails & Integrity Constraints
- Apple-native only; no third-party packages.
- Headless SDK boundary: no UI changes.
- PURELY mechanical — no behavioral change to the fishing state machine.
- Touch ONLY Sources/Services/FishingEngine.swift and Tests/PodMonstersTests/FishingTests.swift.

## Requirements
### R1. Remove the synchronous main-thread helper
- Delete the `updateOnMainThread(_:)` helper and every `DispatchQueue.main.sync` call in
  FishingEngine.swift. Inline each method body; rely on the existing `@MainActor` isolation.

### R2. Preserve behavior exactly
- All existing FishingTests must pass unchanged. Do NOT edit test assertions to force a pass.

## Acceptance Criteria
- [ ] Zero occurrences of `DispatchQueue.main.sync` or `updateOnMainThread` in FishingEngine.swift.
- [ ] `swift test` passes — 151 tests, 0 failures (count unchanged).
- [ ] `swift build -Xswiftc -strict-concurrency=complete` compiles with 0 warnings.
- [ ] `/code-review` (Claude Opus 4.6 Thinking) passes the concurrency checklist.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- Run /code-review on the diff with the reviewer model.
```

---

## M-A1 — HealthKit ingestion layer   ·   run with `/goal`

```
# Teamwork Project Prompt — M-A1: HealthKit Ingestion Layer

> Goal: A headless, fully unit-testable HealthKit ingestion layer behind a provider protocol —
> the data spine for both the wellness app and the familiar economy. Mirror the provider+mock
> pattern already used in BiomeScanner.swift.
> Working directory: /Users/stevendiaz/Pod monsters
> Integrity mode: development

## Reference Materials (read first)
- Sources/Services/BiomeScanner.swift — COPY this pattern: protocol + real impl + mock impl +
  test-environment detection, AND the `#if canImport(WeatherKit)` framework guard.
- docs/pod-monsters-concept.md §15 — the health/biome signals the game relies on.
- ROADMAP.md — milestone M-A1, the file-ownership map, the merge gates.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native: HealthKit (HKHealthStore) only.
- Headless: no UI. Business logic only.
- iOS-ONLY FRAMEWORK GUARD (critical): HealthKit does NOT compile on the macOS host that runs
  `swift test`. Wrap ALL `import HealthKit` / HKHealthStore code in `#if canImport(HealthKit)`,
  exactly mirroring the `#if canImport(WeatherKit)` block in BiomeScanner.swift. Where HealthKit
  is unavailable (the test host), the mock is used and the package still compiles.
- NO real HealthKit calls in the test path — gate them out under test like RealWeatherProvider does.
- FILE OWNERSHIP: create ONLY under Sources/Services/Health/* and Tests/PodMonstersTests/.
  Do NOT edit GameSession.swift, GameConstants.swift, or ANY existing source file — expose protocol
  + types only. Integration into the game loop is a separate later milestone.

## Requirements
### R1. HealthDataProvider protocol + two implementations
- `HealthDataProvider` protocol exposing the R2 signals as async functions.
- `HealthKitDataProvider` — real impl backed by HKHealthStore (under `#if canImport(HealthKit)`),
  with authorization handling.
- `MockHealthDataProvider` — injectable mock returning configurable values for tests.
- Mirror BiomeScanner's provider structure and test-detection.

### R2. Signals to surface (each a typed model)
- Daily steps, walking/running distance, active energy.
- Heart rate, HRV (SDNN).
- Sleep (asleep duration; stages if available).
- Mindful minutes.
- Time in daylight.

### R3. Test-environment safety
- Detect the XCTest environment and default to the mock, so the suite needs no HealthKit entitlement
  and never blocks on permissions.

### R4. Tests
- Mock-driven unit tests for each signal: requested type maps to the right model; authorization-denied
  path handled; empty/zero data handled.

## Acceptance Criteria
- [ ] `HealthDataProvider` + real `HealthKitDataProvider` + `MockHealthDataProvider` under Sources/Services/Health/.
- [ ] All HealthKit code is `#if canImport(HealthKit)`-guarded; `swift test` compiles and runs on the macOS host using the mock.
- [ ] Every R2 signal is represented and unit-tested via the mock.
- [ ] No real HKHealthStore call executes in the test path.
- [ ] No file outside Sources/Services/Health/ and Tests/ was modified.
- [ ] `swift test` passes (count increases by the new tests; update docs/status/CURRENT.md via /handoff).
- [ ] `swift build -Xswiftc -strict-concurrency=complete` compiles with 0 warnings.
- [ ] `/code-review` (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review the branch with the reviewer model; /handoff to update CURRENT.md.
```

---

## M-A2 — Wellness Session Core   ·   run with `/goal`

```
# Teamwork Project Prompt — M-A2: Wellness Session Core

> Goal: Define the shared WellnessSession abstraction every pillar conforms to — the spine of the
> "equip a familiar → do a session → it levels" loop. Headless, fully unit-testable.
> Working directory: /Users/stevendiaz/Pod monsters
> Integrity mode: development

## Reference Materials (read first)
- Sources/Services/Health/* — the HealthDataProvider + signal types from M-A1 that sessions read.
- Sources/Core/Monster.swift — the familiar a session is equipped with (reference by id only; do NOT edit it).
- Sources/Services/BiomeScanner.swift — protocol/provider style to match.
- ROADMAP.md — milestone M-A2, file-ownership map, merge gates, and the "wellness session" definition.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless (no UI); @MainActor where state-bound.
- FILE OWNERSHIP: create ONLY under Sources/Core/Session/* and Tests/PodMonstersTests/.
  Reference Monster by `Monster.id` only. Do NOT edit Monster.swift, GameSession.swift,
  GameConstants.swift, or any existing file. The economy integration is a later milestone.
- This is a PROTOCOL/ABSTRACTION milestone — define the shared contract, not pillar specifics.

## Requirements
### R1. WellnessSession protocol
- `WellnessSession` with:
  - `type: SessionType` (enum `.cardio` → .kinetic, `.strength` → .forge, `.meditation` → .aether faction mapping).
  - `equippedFamiliarID: UUID` (the Monster earning this session).
  - lifecycle: `start()`, signal accumulation during the session, `finalize() -> SessionSummary`.

### R2. SessionSummary (the economy's contract)
- A Codable `SessionSummary` carrying: type, equipped familiar id, start/end, duration, captured signals (R3),
  and an `EffortEnvelope` (R4). This is the single output the economy will read.

### R3. Captured signals (shared shape)
- Common: duration, HR samples / HR rise, movement/activity level, context (location/biome tag).
- Type-specific payloads (strength sets, meditation stillness, etc.) attach via the conforming pillar — define
  an extensible carrier (associated payload type or typed enum) so pillars add their data without editing this.

### R4. EffortEnvelope (PERMISSIVE this milestone)
- Derives a `verificationTier` (`.verified` / `.selfReported` / `.unverified`) from HR rise + movement + context.
- DEFAULT NOW: permissive — any started/finalized session resolves to at least `.selfReported` (everything logs
  and earns). Real gating thresholds are a later tuning pass; keep thresholds in clearly-named constants.

### R5. Equip mechanism
- Attach an equipped familiar id to a session at creation, carried through to the summary.

### R6. Tests
- Create a session with an equipped familiar, accept mock signals, finalize() to a SessionSummary.
- Summary round-trips (Codable). Envelope resolves to the permissive default for a normal session.

## Acceptance Criteria
- [ ] `WellnessSession` + `SessionType` + `SessionSummary` + `EffortEnvelope` under Sources/Core/Session/.
- [ ] A session with an equipped familiar id accumulates mock signals and finalizes to a summary.
- [ ] Envelope is permissive (normal session → at least .selfReported); thresholds in named constants.
- [ ] References Monster by id only; NO existing file modified.
- [ ] `swift test` passes (count increases; update CURRENT.md via /handoff).
- [ ] `swift build -Xswiftc -strict-concurrency=complete` — 0 warnings.
- [ ] `/code-review` (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review; /handoff.
```

---

## M-A3 — Strength Session (logger)   ·   run with `/goal` (own git worktree)

```
# Teamwork Project Prompt — M-A3: Strength Session (Logger)

> Goal: A strength logger conforming to WellnessSession — self-reported sets/reps/weight with
> progressive-overload pre-fill, plus passive capture into the session envelope. Tracking TRUSTS input;
> reward-gating is a later tuning layer. Headless, fully unit-testable.
> Working directory: /Users/stevendiaz/Pod monsters (worktree)
> Integrity mode: development

## Reference Materials (read first)
- Sources/Core/Session/* — the WellnessSession protocol + SessionSummary + EffortEnvelope to conform to (M-A2).
- ROADMAP.md — milestone M-A3, file-ownership map, merge gates.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless (no UI); @MainActor where state-bound.
- FILE OWNERSHIP: create ONLY under Sources/Core/Strength/* and Tests/PodMonstersTests/.
  Do NOT edit Session/*, Monster.swift, or any existing file. Conform to WellnessSession; do not modify it.
- Manual entry is TRUSTED here (honest logging + full history). Do NOT add reward-gating — that's the economy's job later.

## Requirements
### R1. Exercise library + routine templates
- Exercise model (name, category/muscle, equipment) and reusable routine templates (ordered exercises with target sets).

### R2. Strength session conforming to WellnessSession
- `StrengthSession: WellnessSession` (type `.strength`) logging sets: reps, weight, optional RPE, per exercise. Self-reported values accepted as-is.

### R3. Progressive-overload pre-fill
- Given a template + prior history, pre-fill each set with last session's values and suggest the next load
  (small configurable increment). In-session logging is "confirm or adjust," not blank entry.

### R4. Volume / PRs
- Compute per-session volume (Σ reps×weight) and detect PRs (max weight or estimated 1RM per exercise) from history.

### R5. Passive capture into the envelope
- Accept mockable passive inputs (rep tempo, rest duration, HR) and fold them into the EffortEnvelope on finalize.

### R6. Tests
- Log against a template; pre-fill from history; suggest next load. Volume + PR correct.
- finalize() yields a conforming SessionSummary with a populated EffortEnvelope. Persists / round-trips.

## Acceptance Criteria
- [ ] Exercise library + templates + `StrengthSession: WellnessSession` under Sources/Core/Strength/.
- [ ] Self-reported sets/reps/weight log honestly; pre-fill + next-load suggestion work from history.
- [ ] Volume + PR detection correct; finalize() returns a conforming SessionSummary with an EffortEnvelope.
- [ ] Conforms to the M-A2 protocol WITHOUT modifying it; no existing file modified.
- [ ] `swift test` passes (count increases; update CURRENT.md via /handoff).
- [ ] `swift build -Xswiftc -strict-concurrency=complete` — 0 warnings.
- [ ] `/code-review` (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review; /handoff.
```

---

## M-A4 — Meditation Session   ·   run with `/goal` (own git worktree)

```
# Teamwork Project Prompt — M-A4: Meditation Session

> Goal: A meditation/mindfulness session conforming to WellnessSession — breathing patterns,
> stillness/HRV, mindful minutes. Headless, fully unit-testable.
> Working directory: /Users/stevendiaz/Pod monsters (worktree)
> Integrity mode: development

## Reference Materials (read first)
- Sources/Core/Session/* — the WellnessSession protocol + SessionSummary + EffortEnvelope (M-A2).
- Sources/Services/FishingEngine.swift — existing breathing-tempo / stillness / parasympathetic logic to
  reuse concepts from (do NOT edit it).
- ROADMAP.md — milestone M-A4, file-ownership map, merge gates.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless (no UI); @MainActor where state-bound.
- FILE OWNERSHIP: create ONLY under Sources/Core/Mindfulness/* and Tests/PodMonstersTests/.
  Do NOT edit Session/*, FishingEngine.swift, or any existing file. Conform to WellnessSession; don't modify it.

## Requirements
### R1. Meditation session conforming to WellnessSession
- `MeditationSession: WellnessSession` (type `.meditation`) with a session lifecycle.

### R2. Breathing patterns
- Configurable patterns (incl. 4-7-8) with correct phase timing (inhale/hold/exhale/hold durations + cycle counts).

### R3. Stillness / HRV signals
- Accept mockable stillness + HRV inputs during the session; fold into the EffortEnvelope on finalize.

### R4. Mindful minutes
- Track accumulated mindful minutes (the value that would later be written to HealthKit Mindful Minutes).

### R5. Tests
- Lifecycle works; pattern phase timing correct (e.g. one 4-7-8 cycle totals 19s).
- Mock stillness/HRV fold into the envelope; mindful minutes accumulate. finalize() yields a conforming SessionSummary.

## Acceptance Criteria
- [ ] `MeditationSession: WellnessSession` + breathing-pattern model under Sources/Core/Mindfulness/.
- [ ] Pattern phase timing correct; mindful minutes accumulate; stillness/HRV fold into the envelope.
- [ ] finalize() returns a conforming SessionSummary; conforms to M-A2 protocol unmodified; no existing file modified.
- [ ] `swift test` passes (count increases; update CURRENT.md via /handoff).
- [ ] `swift build -Xswiftc -strict-concurrency=complete` — 0 warnings.
- [ ] `/code-review` (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review; /handoff.
```

---

## M-A5 — Cardio Session   ·   run with `/goal` (own git worktree)

```
# Teamwork Project Prompt — M-A5: Cardio Session

> Goal: A cardio/steps session conforming to WellnessSession — distance, cadence, HR zones, steps.
> Headless, fully unit-testable.
> Working directory: /Users/stevendiaz/Pod monsters (worktree)
> Integrity mode: development

## Reference Materials (read first)
- Sources/Core/Session/* — the WellnessSession protocol + SessionSummary + EffortEnvelope (M-A2).
- Sources/Services/Health/* — step/distance/HR signal types from M-A1 to consume.
- ROADMAP.md — milestone M-A5, file-ownership map, merge gates.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless (no UI); @MainActor where state-bound.
- FILE OWNERSHIP: create ONLY under Sources/Core/Cardio/* and Tests/PodMonstersTests/.
  Do NOT edit Session/*, Health/*, or any existing file. Conform to WellnessSession; don't modify it.

## Requirements
### R1. Cardio session conforming to WellnessSession
- `CardioSession: WellnessSession` (type `.cardio`) with a session lifecycle.

### R2. Metrics
- Aggregate distance, steps, cadence (steps/min), and pace from mockable inputs.

### R3. HR-zone classification
- Classify time-in-zone from HR samples + a max-HR (or configurable zone boundaries). Expose the zone breakdown.

### R4. Fold into envelope
- Cadence + HR-zone + distance fold into the EffortEnvelope on finalize.

### R5. Tests
- Distance/steps/cadence aggregation correct; HR-zone classification correct at boundaries.
- finalize() yields a conforming SessionSummary.

## Acceptance Criteria
- [ ] `CardioSession: WellnessSession` + zone-classification logic under Sources/Core/Cardio/.
- [ ] Distance/steps/cadence aggregation + HR-zone breakdown correct.
- [ ] finalize() returns a conforming SessionSummary; conforms to M-A2 protocol unmodified; no existing file modified.
- [ ] `swift test` passes (count increases; update CURRENT.md via /handoff).
- [ ] `swift build -Xswiftc -strict-concurrency=complete` — 0 warnings.
- [ ] `/code-review` (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review; /handoff.
```

---

### Running the set
1. **M-A0 solo** under `/goal` (Flash, High). Finish, `/code-review` with Opus 4.6, merge. Validates the loop.
2. **M-A1** under `/goal`, then merge. **M-A2** under `/goal`, then merge. (A2 depends on A1; A3–A5 depend on A2.)
3. **Wave [M-A3, M-A4, M-A5]** — three `/goal` agents, each in its own `git worktree` (see `docs/WORKFLOW.md`).
   Separate folders → branches merge in any order, zero conflicts. Three PRs, review + merge each.
4. None of these touch shared files; the economy wiring (Phase B) is a later single-owner integration pass.
