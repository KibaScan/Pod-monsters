# Pod Monsters — Phase B Agent Prompts (Economy)

> The Podmon economy — how real wellness sessions level your Podmons.
>
> **Prereqs:** Phase A merged (M-A1 ingestion, M-A2 `WellnessSession` + `SessionSummary`, M-A3–A5 pillars)
> **and** the M-A0.5 rename (the creature type is `Podmon`).
>
> **RUN MODE — every milestone here runs under `/goal`, NOT `/teamwork-preview`.** These are new modules
> inside the existing SDK plus one integration refactor; a peer squad would fight over files.
>
> **Builder model:** Gemini 3.5 Flash (High).
> **Reviewer (the `/code-review` gate):** Claude Opus 4.6 (Thinking) — the independent auditor `/goal`
> won't run on itself.
> **Working directory:** `/Users/stevendiaz/Pod monsters` · **Integrity mode:** development
>
> **ORDER:** B1 → B2 → B3, sequential. B2 consumes B1; B3 is a shared-file integration pass (solo).
>
> **NUMBERS:** every rate / ceiling curve / bond weight / equip-bonus lives in a named constant and is a
> **placeholder tuned by a human later** — the agent must not invent balance values. (Open decision #3.)

---

## M-B1 — Progression: XP / ceiling / bond   ·   run with `/goal` (SOLO)

```
# Teamwork Project Prompt — M-B1: Progression (XP / Ceiling / Bond)

> Goal: The dual-source progression model. Game XP fills a Podmon toward its stat ceilings with
> diminishing returns; ONLY real-world effort raises the ceiling and builds bond. Bond goes dormant,
> never decays. Headless, fully unit-testable.
> Working directory: /Users/stevendiaz/Pod monsters
> Integrity mode: development

## Reference Materials (read first)
- Sources/Core/Podmon.swift — the creature whose stats/ceiling/bond this governs (post-rename type).
- ROADMAP.md — North Star (economy rules + wellness guardrails), milestone M-B1, the merge gates.
- docs/DECISIONS.md — D-01 (concurrency), D-05 (naming).
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless; @MainActor where state-bound; D-01 concurrency rules (NO DispatchQueue.main.sync, NO locks).
- WELLNESS GUARDRAILS (non-negotiable): bond goes DORMANT, never decays — no "losing progress." Returns
  are soft/diminishing, never a hard "locked." Never punish a fit-but-busy user.
- FILE OWNERSHIP: logic lives in Sources/Core/Progression/* + tests. Adding ceiling/bond STATE to
  Podmon.swift is allowed but must be ADDITIVE and focused (new stored fields + small helpers only) — do
  NOT change existing Podmon behavior and do NOT touch GameSession.swift. Runs SOLO (it touches Podmon.swift).
- NUMBERS are placeholders: put every rate/threshold/curve in a clearly-named `ProgressionConstants`
  (NOT GameConstants — the integration pass M-B3 consolidates). A human tunes these later.

## Requirements
### R1. Stat ceilings
- Each stat (speed, agility, power, hp, focus, special) gains a `ceiling`. Game XP raises the stat toward
  its ceiling and can NEVER exceed it.

### R2. Real effort raises ceiling + bond
- An `applyRealEffort(...)` path is the ONLY thing that raises ceilings and increases `bond`. Game-only
  XP raises neither.

### R3. Bond
- `bond` is per-Podmon, built only by real effort. After inactivity it goes DORMANT (flag/timestamp); it
  does NOT decrease. A "welcome back" resumes it. (Bond will weight battles in Phase C.)

### R4. Diminishing returns
- Define the curve so game XP yields ever-smaller stat gains as a stat approaches its ceiling — a
  game-grinder asymptotes and stalls; a trained Podmon (high ceiling) keeps climbing. Curve params in `ProgressionConstants`.

### R5. Tests
- Game XP raises a stat toward but never past its ceiling; gains shrink near the ceiling.
- applyRealEffort raises the ceiling and bond; game XP does not.
- Bond goes dormant on inactivity and never decreases; resumes on return.

## Acceptance Criteria
- [ ] Ceiling + bond model under Sources/Core/Progression/ (additive fields on Podmon only if needed).
- [ ] Game XP fills toward ceiling with diminishing returns, never exceeds it.
- [ ] Only the real-effort path raises ceiling + bond; bond is dormant-not-decaying.
- [ ] All numbers in `ProgressionConstants`; GameSession.swift untouched.
- [ ] swift test passes (count increases); update CURRENT.md via /handoff.
- [ ] swift build -Xswiftc -strict-concurrency=complete — 0 warnings.
- [ ] /code-review (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review ; /handoff ; /check-numbers
```

---

## M-B2 — Economy: session → game mapping   ·   run with `/goal`

```
# Teamwork Project Prompt — M-B2: Economy (Session → Game Mapping)

> Goal: Translate a finalized WellnessSession's SessionSummary into XP / ceiling / bond effects on the
> EQUIPPED Podmon, per faction, honoring the equip bonus and the EffortEnvelope's verification tier.
> Headless, fully unit-testable.
> Working directory: /Users/stevendiaz/Pod monsters
> Integrity mode: development

## Reference Materials (read first)
- Sources/Core/Session/* — `SessionSummary` + `EffortEnvelope` (verification tier). This is the INPUT.
- Sources/Core/Progression/* — the ceiling/bond model from M-B1. This is what the mapping drives.
- Sources/Core/Podmon.swift — the equipped Podmon that earns.
- ROADMAP.md — North Star (economy rules), milestone M-B2, the merge gates.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless; @MainActor where state-bound; D-01 concurrency rules.
- FILE OWNERSHIP: Sources/Core/Economy/* + tests. CONSUME M-A2 + M-B1 without modifying them. Do NOT
  edit GameSession.swift — that is the integration pass M-B3.
- TRACKING/REWARD DECOUPLING (the core rule): a self-reported session still earns XP toward the ceiling
  (it counts, it's fair) but raises ceiling/bond little-to-none; a VERIFIED session raises ceiling + bond.
  This mapper is the ONLY place the verification tier gates reward.
- NUMBERS are placeholders in named constants — a human tunes these later.

## Requirements
### R1. Session type → faction
- `.cardio` → kinetic, `.strength` → forge, `.meditation` → aether. Matched faction earns full rate; any
  cross-faction contribution earns at a reduced rate.

### R2. Apply to the equipped Podmon
- Read the equipped-Podmon id from the SessionSummary, resolve the Podmon, and apply effects via the M-B1
  model (game XP path vs. real-effort path per R4). Handle "no Podmon equipped" gracefully (no crash, no reward).

### R3. Equip bonus
- An equipped Podmon whose faction matches the session type gets a configurable bonus multiplier.

### R4. Verification gating (the decoupling)
- From `EffortEnvelope.verificationTier`:
  - `.verified` → real-effort path: XP + ceiling raise + bond.
  - `.selfReported` → game-XP path only: XP toward the ceiling, minimal/zero ceiling raise, minimal bond.
  - `.unverified` → minimal. Thresholds are placeholders.

### R5. Tests
- A mock SessionSummary (type, tier) produces the correct faction XP / ceiling / bond deltas on the equipped Podmon.
- Equip bonus applies for the matching faction; cross-faction is reduced.
- self-reported → XP-toward-ceiling only; verified → ceiling + bond rise.
- No Podmon equipped → handled gracefully.

## Acceptance Criteria
- [ ] Economy mapper under Sources/Core/Economy/ consuming `SessionSummary` and driving the M-B1 model.
- [ ] Type→faction mapping, equip bonus, and cross-faction reduction all correct.
- [ ] Verification tier gates reward exactly as specified (self-reported = XP only; verified = ceiling + bond).
- [ ] M-A2 + M-B1 consumed unmodified; GameSession.swift untouched; numbers in named constants.
- [ ] swift test passes (count increases); update CURRENT.md via /handoff.
- [ ] swift build -Xswiftc -strict-concurrency=complete — 0 warnings.
- [ ] /code-review (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review ; /handoff ; /check-numbers
```

---

## M-B3 — Integration: wire session → economy → GameSession   ·   run with `/goal` (SOLO, shared files)

```
# Teamwork Project Prompt — M-B3: Economy Integration

> Goal: Connect the foundation end-to-end — a finalized wellness session routes rewards through the
> economy to the equipped Podmon — and consolidate tuning constants. Shared-file integration pass.
> Working directory: /Users/stevendiaz/Pod monsters
> Integrity mode: development

## Reference Materials (read first)
- Sources/Core/GameSession.swift — the coordinator being wired (this milestone edits it).
- Sources/Services/Health/*, Sources/Core/Session/*, Sources/Core/{Strength,Mindfulness,Cardio}/*,
  Sources/Core/Progression/*, Sources/Core/Economy/* — everything being connected.
- Sources/Core/GameConstants.swift — destination for the consolidated tuning constants.
- ROADMAP.md — milestone M-B3, the file-ownership "Shared (integration only)" rule, the merge gates.
- GEMINI.md — build/test/concurrency rules.

## Guardrails & Integrity Constraints
- Apple-native; headless; @MainActor; D-01 concurrency rules (NO DispatchQueue.main.sync, NO locks).
- SHARED-FILE PASS — runs SOLO, sequentially, AFTER B1 and B2 are merged. This is the ONE milestone
  allowed to edit GameSession.swift and GameConstants.swift.
- Preserve existing behavior and every existing test. This wires modules together; it does not rewrite them.

## Requirements
### R1. Wire the loop
- In GameSession: equip a Podmon → run/finalize a WellnessSession → its SessionSummary flows through the
  M-B2 economy → the equipped Podmon's XP / ceiling / bond update. Keep the evolution checks firing as today.

### R2. Consolidate constants
- Move `ProgressionConstants` and any economy constants into `GameConstants` (one tuning surface), updating references.

### R3. Integration tests
- End-to-end: a finalized session of EACH type updates the equipped Podmon correctly through the full chain.
- A self-reported vs. verified session produces the expected ceiling/bond difference end-to-end.

## Acceptance Criteria
- [ ] GameSession wires session → economy → Podmon; evolution still fires; existing tests unchanged.
- [ ] Tuning constants consolidated into GameConstants.
- [ ] Integration tests cover the full chain for each session type and verification tier.
- [ ] swift test passes (count increases); update CURRENT.md via /handoff.
- [ ] swift build -Xswiftc -strict-concurrency=complete — 0 warnings.
- [ ] /code-review (Claude Opus 4.6 Thinking) passes.

## Verify
- swift test
- swift build -Xswiftc -strict-concurrency=complete
- /code-review ; /handoff ; /check-numbers
```

---

### Running Phase B
1. **B1 solo** (touches `Podmon.swift`) → merge.
2. **B2** (new `Economy` folder, consumes B1 + M-A2) → merge.
3. **B3 solo** — the shared-file integration pass on `GameSession.swift` + `GameConstants.swift`, after B1 and B2 are merged.
4. After B3 the vertical slice is real: **equip a Podmon → do a session → it levels.** The battle engine (Phase C) reads those stats + bond next.

> Reminder: the balance numbers are deliberately placeholders. Once the slice runs, tune `GameConstants`
> by feel (open decision #3) — don't let an agent pick them.
