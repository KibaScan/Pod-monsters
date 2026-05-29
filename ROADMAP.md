# Pod Monsters — Roadmap & Autonomous Build Plan

> Source of truth for what to build, in what order, and how the agent swarm runs it.
> Pairs with `docs/DECISIONS.md` (architecture decisions) and `docs/status/CURRENT.md` (rolling state).

---

## North Star

Real life is the training; the game world is the adventure. Wellness behavior is the **input**, the RPG (story + Pokémon-style battles) is the **payoff**, and the product *is* the reinforcement loop between them.

**The economy (the moat):**
- XP is earnable **both** in-game and IRL (so rest days and busy weeks stay playable).
- Only **real-world effort** raises a familiar's **stat ceiling** and builds its **bond**. Game XP fills *toward* the ceiling with hard diminishing returns; it can't lift it.
- A game-only grinder tops out and stalls; a trained player blows past that wall. That gap is the moat.
- Neglecting the game bottlenecks your *in-game expression* (you must play to spend banked potential), **never** your health. We never punish someone for being fit-but-busy.

**Wellness guardrails (non-negotiable, design-level):**
- Bond goes **dormant**, never decays. No "you're losing progress" guilt loops.
- Soft bottlenecks (diminishing returns + raisable ceilings), never hard "LOCKED" walls.
- Reward *sustainable* behavior, not engagement-maximization. Rest is modeled as a reward.
- All balance numbers live in `GameConstants` and are **tuning decisions for a human**, not values an agent bakes in.

---

## Operating Model (how the swarm runs)

**Model roles** (Antigravity lineup — pick per task)
- **Gemini 3.5 Flash (High)** — Primary driver + credit furnace. Currently the strongest coding/agentic model available here (beats 3.1 Pro on Terminal-Bench 2.1, MCP Atlas, Finance Agent), ~4x faster, and natively fans out into parallel subagents (plan / build / test / fix) inside one run. Does the bulk of building + orchestration; its high token usage is what drains the 35k overage (the point).
- **Claude Opus 4.6 (Thinking)** — Cross-vendor reviewer + tie-breaker. Runs `/code-review` as the merge gate and breaks ties on design calls. Dated vs. current Claude, but its value is *failing differently than a Gemini builder* — catches bugs same-vendor review misses. Low volume. (Sonnet 4.6 for a cheaper gate.)
- **Gemini 3.1 Pro (High)** — Fallback only where Flash trails: long-context and the hardest reasoning. Same-vendor, so NOT your review diversity.
- **GPT-OSS 120B** — Optional cheap third opinion / disposable grunt work.

**Use Antigravity's native orchestration — don't hand-roll it:**
- **Manager View** runs the parallel agents (one per milestone branch) so you're not juggling terminals.
- **Goal prompts** are the hand-off: feed a milestone's requirements + acceptance criteria + verify command (the `ORIGINAL_REQUEST.md` format) and let it plan/execute.
- **Dynamic subagents** let one Flash run fan out into plan → build → test → self-review.
- **Artifacts + inline comments** are the lightweight review channel — comment on the plan/diff and it applies feedback without restarting.
- **Strict mode + sandboxing** for autonomous runs, so a bad step is contained and resettable.

**Execution mode — which command to invoke:**
- **Per milestone → `/goal`.** Hub-and-spoke: one coordinator that dynamically spawns *background* helper subagents (research, audit) while it owns and edits files in place. Safe inside the existing SDK. Approve its plan once, then let it run to completion — not pausing for approval is the whole point of the prefix.
- **Across milestones → parallel `/goal` agents**, one per *non-overlapping folder* (`Health/`, `Workout/`, `Mindfulness/`, `Cardio/`). The file-ownership map is what prevents the file-fighting a shared workspace would cause.
- **`/teamwork-preview` → true greenfield only.** Its fixed Developer/Tester/Auditor squad edits concurrently and fights over files in a tightly-coupled package; almost everything here is "new modules *inside* an existing SDK," which is `/goal`'s lane. (Also may be unavailable on Ultra — check your `/` list before relying on it.)
- **The auditor `/goal` lacks → your Claude `/code-review` gate.** `/goal` self-certifies via standard self-testing; `/teamwork-preview` has an independent auditor and `/goal` does not. The cross-vendor `/code-review` step *is* that independent audit — it's what makes `/goal` safe to trust, and it's what would have caught the FishingEngine `DispatchQueue.main.sync` miss. Don't skip it.

**Unit of work:** 1 milestone = 1 branch = 1 file-ownership zone, with acceptance criteria + one verify command.

**Per-unit loop:** hand off milestone as a goal → Flash plans/builds (subagents) to green → Claude reviewer runs `/code-review` → merge → `/handoff` + `/check-numbers`.

**Merge gates (all must pass — these make the autonomy safe):**
1. `swift test` — green, count matches `CURRENT.md`
2. `swift build -Xswiftc -strict-concurrency=complete` — zero warnings
3. `./skills/check-numbers/scripts/check_numbers.sh` — no drift
4. `/code-review` (Claude reviewer) — pass

**Parallelism:** spawn one agent per non-overlapping milestone in Manager View (assign, don't self-claim). The file-ownership map below guarantees no collisions. Shared files only in integration passes (single-owner, sequential).

**In scope for autonomy:** headless, testable Swift.
**Not in scope (hands-on only):** UI/UX, economy tuning numbers, narrative/content, art.

**How to run a wave**
1. Pick 3–4 milestones from the same phase with non-overlapping owner files.
2. In Manager View, spawn one `/goal` agent per milestone (each in its own folder). Each: `/boot`, then its prompt.
3. As each branch goes green, a Claude reviewer agent runs `/code-review` against the gates.
4. Merge passing branches. Run an integration milestone if the wave needs wiring.
5. `/handoff` + `/check-numbers` to close the wave.

---

## File-Ownership Map

| Zone | Files (owner) | Notes |
|---|---|---|
| Health ingestion | `Sources/Services/Health/*` + tests | new |
| Wellness session core | `Sources/Core/Session/*` + tests | new; the shared abstraction A3–A5 conform to |
| Strength logger | `Sources/Core/Strength/*` + tests | new (was "Workout") |
| Mindfulness | `Sources/Core/Mindfulness/*` + tests | new |
| Cardio/steps | `Sources/Core/Cardio/*` + tests | new |
| Progression/economy | `Sources/Core/Progression/*`, `Sources/Core/Economy/*` + tests | new; keep OFF `GameSession` |
| Battle | `Sources/Core/Battle/*` + tests | new |
| **Shared (integration only)** | `GameSession.swift`, `GameConstants.swift`, `DashboardView.swift` | single-owner, sequential |

Rule: feature milestones expose protocols/types; the coordinator wiring happens in a later integration milestone, never inside a feature branch.

---

## Milestones

### Phase A — Foundation (stable wellness substrate; headless + testable)

**M-A0 · Pipeline smoke test — FishingEngine concurrency cleanup**
- Goal: remove the banned `updateOnMainThread` / `DispatchQueue.main.sync`; rely on `@MainActor`.
- Owner: `Sources/Services/FishingEngine.swift`, `Tests/PodMonstersTests/FishingTests.swift`
- Acceptance: zero `DispatchQueue.main.sync` in file; `/code-review` clean; all tests still pass.
- Verify: gates 1–4. **Run this one first, solo, to validate the whole loop.**
- Depends on: none.

**M-A0.5 · Podmon rename (solo refactor)**
- Goal: rename the `Monster` type → `Podmon` (`Monster.swift` → `Podmon.swift`) and all "buddy"/"monster" terminology → "Podmon" (`equippedBuddy` → `equippedPodmon`, `releaseBuddy` → `releasePodmon`, `noBuddyEquipped` → `noPodmonEquipped`, `capturedMonsters` → `capturedPodmons`, etc.) across sources AND tests. Behavior unchanged. Establishes the vocabulary so every later module is born as `Podmon`. (Starter names Zephyr/Basalt/Lumina and the `Faction` enum stay — they're individual names, not the category.)
- Owner: shared — `Monster.swift`→`Podmon.swift`, `GameSession.swift`, all Views, all Tests. **Runs SOLO.**
- Acceptance: zero references to old names (`Monster` type, `equippedBuddy`, `releaseBuddy`, `noBuddyEquipped`, `capturedMonsters`); all 151 tests pass unchanged; strict-concurrency clean; `/code-review` pass.
- Verify: gates 1–4.
- Depends on: M-A0. **Run before M-A1 onward.**

**M-A1 · HealthKit ingestion layer**
- Goal: `HealthDataProvider` protocol with a real `HKHealthStore` impl + a mock impl (mirror the existing `WeatherProvider`/`BiomeNetworkProvider` pattern). Surfaces steps, workouts, active energy, HR, HRV, sleep, mindful minutes, daylight time.
- Owner: `Sources/Services/Health/*` + tests.
- Acceptance: protocol + real + mock; mock-driven tests cover each signal; no real HealthKit call in test path; `@MainActor` where state-bound.
- Verify: gates 1–4.
- Depends on: none. *(This is the data spine for both the app and the economy — prioritize.)*

**M-A2 · Wellness Session Core**
- Goal: the shared `WellnessSession` abstraction every pillar conforms to. Defines: session `type` (faction-mapped), an equipped-Podmon reference (by `Podmon.id`), the lifecycle (start → accumulate signals → finalize), a `SessionSummary` output the economy will consume, and an `EffortEnvelope` (HR rise + movement + context → verification tier). The envelope is PERMISSIVE by default — everything logs and earns; real gating is a later tuning pass.
- Owner: `Sources/Core/Session/*` + tests.
- Acceptance: protocol + `SessionSummary` + permissive `EffortEnvelope`; a session can be created with an equipped Podmon, accumulate mock signals, and finalize to a summary; references Podmon by id only — NO edits to `Podmon.swift` or `GameSession.swift`.
- Verify: gates 1–4.
- Depends on: M-A1 (reads its signal types).

**M-A3 · Strength session (logger)**
- Goal: strength logging that conforms to `WellnessSession` — exercise library, routine templates, set/rep/weight logging (self-reported), progressive-overload pre-fill so in-session entry collapses to "confirm," and passive capture (rep tempo, rest, HR) into the session's envelope. Tracking TRUSTS input; reward-gating is a later tuning layer. (The shield-crack game mechanic sits on top of this later, separately.)
- Owner: `Sources/Core/Strength/*` + tests.
- Acceptance: log a session against a template; pre-fill last values + suggest next load; compute volume/PRs; produces a conforming `SessionSummary` with a captured envelope.
- Verify: gates 1–4.
- Depends on: M-A2 (+ M-A1).

**M-A4 · Meditation session**
- Goal: meditation/mindfulness conforming to `WellnessSession` — breathing patterns (incl. 4-7-8), stillness/HRV, mindful-minutes write-back. Headless.
- Owner: `Sources/Core/Mindfulness/*` + tests.
- Acceptance: session lifecycle; pattern timing correct; produces a conforming `SessionSummary`.
- Verify: gates 1–4.
- Depends on: M-A2.

**M-A5 · Cardio session**
- Goal: cardio/steps conforming to `WellnessSession` — distance, cadence, HR-zone, daily-steps. Headless.
- Owner: `Sources/Core/Cardio/*` + tests.
- Acceptance: zone classification; cadence/distance aggregation; produces a conforming `SessionSummary`.
- Verify: gates 1–4.
- Depends on: M-A2.

> **Sequence:** M-A0 solo → M-A0.5 rename (solo) → M-A1 → M-A2 (session core) → parallel wave [M-A3, M-A4, M-A5] (separate folders, all conform to the session protocol, so they don't collide).

### Phase B — Economy (the familiar system)

**M-B1 · XP / ceiling / bond model**
- Goal: dual-source XP; IRL-only ceiling raises; IRL-only bond; diminishing returns near ceiling. Put new logic in `Sources/Core/Progression/*` (NOT `GameSession`/`Podmon` directly, to avoid the integration bottleneck — extend `Podmon` via a small focused additive change only if unavoidable).
- Owner: `Sources/Core/Progression/*` + tests.
- Acceptance: game XP stalls at ceiling; IRL raises ceiling + bond; bond goes dormant (no decay); all thresholds read from `GameConstants` placeholders.
- Verify: gates 1–4.
- Depends on: none (model-level).

**M-B2 · Activity → game mapping**
- Goal: translate ingestion/cardio/workout/mindfulness events into faction XP, ceiling raises, bond, and the equip bonus.
- Owner: `Sources/Core/Economy/*` + tests.
- Acceptance: each activity type maps to the right faction effect; equip bonus applies; cross-faction at reduced rate.
- Verify: gates 1–4.
- Depends on: M-B1.

**M-B3 · Integration pass (sequential, single-owner)**
- Goal: wire ingestion → economy → `GameSession`; centralize constants.
- Owner: `GameSession.swift`, `GameConstants.swift` (+ wiring).
- Acceptance: end-to-end: an activity event flows to a familiar's XP/ceiling/bond; integration tests cover it.
- Verify: gates 1–4.
- Depends on: M-A1–A4, M-B1, M-B2.

### Phase C — Battle Engine (the payoff; headless + testable)

**M-C1 · Combat core**
- Goal: Kinetic/Forge/Aether type triangle; damage formula reading stats + bond; turn order; status effects.
- Owner: `Sources/Core/Battle/*` + tests.
- Acceptance: deterministic damage given inputs; type advantages correct; bond measurably influences outcomes; turn order correct.
- Verify: gates 1–4.
- Depends on: M-B1 (needs the stat/bond model).

**M-C2 · Enemy AI + encounter resolution**
- Goal: opponent move selection; win/lose/rewards; hook a battle win to a story-progress flag.
- Owner: `Sources/Core/Battle/*` + tests.
- Acceptance: AI picks legal/sensible moves; encounter resolves to a reward + progress event.
- Verify: gates 1–4.
- Depends on: M-C1.

> Battle **UI** is deferred to Phase D (needs your eyes).

### Phase D — App shell & UX (mostly hands-on)

Onboarding, home screen, habitat/collection, real navigation, battle UI, meditation/workout UIs. Use Gemini for scaffolding only; you drive the design. Not part of the autonomous waves.

---

## Cross-cutting hardening (good autonomous filler between waves)

- Doc reconciliation — `CURRENT.md` stop overselling "done"; fix README test map (add `MonsterTests.swift`); fix `phase_0_summary.md` tree.
- Strict-concurrency audit across all files (verify gate 2 actually passes everywhere).
- `print` → `os.Logger` (M6).
- ~~Naming: pick `familiar` vs `buddy`~~ — **RESOLVED → "Podmon"**; handled by milestone M-A0.5 (`Monster`→`Podmon`, `buddy`→`Podmon`).
- Fix the `releaseBuddy` `var`→`let` warning — folds into the M-A0.5 rename.
- Run `/pre-launch-checklist` green and record the result (it's never been logged green).

---

## The Vertical Slice (proves the whole thesis)

Equip a familiar → log a real workout (or fire the diagnostic harness) → matched XP + bond rise, ceiling lifts → take it into a turn-based battle where stats + bond decide the result → a win nudges the story forward.

Almost all of it verifies headlessly. Hitting this slice = the loop is real. Everything after is depth and polish.

---

## Open decisions for the human (don't let agents guess these)

1. ~~**Workout tracker depth**~~ — **RESOLVED:** HealthKit aggregates the passive pillars; a focused custom logger handles strength (self-reported numbers, permissive effort-envelope). Tracking and game-reward are decoupled — log honestly, gate power on the envelope later.
2. ~~**Familiar vs. buddy**~~ — **RESOLVED:** the creatures are **Podmons** (one **Podmon**, many **Podmons**). `Podmon` is the code type; "Podmons" in user-facing copy; the collection screen is the **Pod-dex**. Milestone M-A0.5 sweeps the `Monster`→`Podmon` rename. (D-05)
3. **Economy tuning** — equip-bonus size, ceiling curve, bond's battle weight, XP rates.
4. **Hybrid evolution stat tables** — currently cosmetic (same +20 to all); decide real divergent stats.
5. **Story scope** — region map? gym-leader analogs? how battles gate on real training.
