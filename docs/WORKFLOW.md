# Pod Monsters — Dev Workflow

> How code gets from an agent to `main`. Trunk-based, short-lived branches, `main` always green.
> The PR is the control surface over the agents — you review diffs and merge; you never push feature work to `main` directly.

## Principles
- **Trunk-based.** One long-lived branch (`main`). Everything else is a short-lived feature branch (hours, not days).
- **`main` is always green.** It always builds, all tests pass, strict-concurrency is clean. Never merge red.
- **One milestone = one branch = one PR**, scoped to a single file-ownership zone (see `ROADMAP.md`).
- **The PR is the gate.** Even solo, every change lands via PR so CI and the reviewer run on it.

## Branch naming
`m-<milestone>-<slug>` — e.g. `m-a1-healthkit-ingestion`, `m-a3-strength`, `m-b1-progression`.

## Single-milestone flow
1. **Branch:** `git checkout main && git pull && git checkout -b m-a1-healthkit-ingestion`
2. **Build:** in the agent (Gemini 3.5 Flash, High), `/goal` + the milestone prompt. Approve the plan once; it runs to green.
3. **Commit:** conventional commits — `feat(health): add HealthDataProvider protocol + mock`.
4. **PR:** `git push -u origin <branch>` then `gh pr create` (title = milestone; body = what changed + test delta).
5. **Gates run** (below). Fix on the branch until green.
6. **Merge:** `gh pr merge --squash --delete-branch` — one tidy commit per milestone on `main`.
7. **Close out:** `/handoff` updates `docs/status/CURRENT.md`; `/check-numbers` confirms no drift.

## Merge gates (all four — none skipped)
1. **`swift test`** — green, count matches `CURRENT.md`. → enforced by CI.
2. **Strict concurrency** — `swift build -Xswiftc -strict-concurrency=complete`, zero warnings. → enforced by CI (warnings-as-errors).
3. **No doc drift** — `./skills/check-numbers/scripts/check_numbers.sh`. → pre-commit hook + close-out.
4. **Independent review** — a second agent on **Claude Opus 4.6 (Thinking)** runs `/code-review` on the diff (the auditor `/goal` won't run on itself): concurrency checklist, file-ownership held, test quality. Plus `secret_scan.sh` pre-push.

CI covers gates 1–2 (`.github/workflows/ci.yml`). Gates 3–4 are the hooks + the reviewer agent.

## Parallel wave (multiple milestones at once)
Agents in one directory fight over the filesystem even on different branches. Use **worktrees** — a separate directory per agent:
```bash
git worktree add ../pm-strength    m-a3-strength
git worktree add ../pm-meditation  m-a4-meditation
git worktree add ../pm-cardio       m-a5-cardio
```
Point one agent at each folder. Because each milestone owns a different source folder (`Strength/`, `Mindfulness/`, `Cardio/`), the branches merge in any order with zero conflicts — three PRs, review + merge each. Clean up with `git worktree remove ../pm-strength`.

**Integration milestones** — anything touching `GameSession.swift` / `GameConstants.swift` (e.g. M-B3) — run **solo and sequentially**, after the feature branches land.

## Branch protection (set once)
GitHub → Settings → Branches → protect `main`:
- Require a pull request before merging.
- Require status check **`swift test`** — enable now; it passes today.
- Add **strict-concurrency** as a required check *once it's green* (see Caveats).
- Require branches to be up to date before merging.

## Autonomy graduation
- **First runs (M-A0, M-A1):** you drive git/PR manually so you see how the agent behaves.
- **Once trusted:** allow-list `git` and `gh` in Antigravity so agents open their own PRs; you only review + merge.

## Budget guardrail
- Credits are **overage-only** ($0.01 each) — ~35k ≈ **$350**, tapped only after the plan quota refreshes. Discrete gated milestones are cheap; all of Phase A + B fits with margin.
- Turn on **AI Credit Overages: Always** deliberately, and set a per-run cap if Antigravity exposes one. **No unbounded macro-goals** — work stays in one-milestone-one-PR units, never one giant fire-and-forget run.
- Quota-drain / lockout bugs are circulating — another reason to run milestones one at a time, not as a swarm.

## Caveats
- **HealthKit is iOS-only — it does NOT compile on the macOS host that runs `swift test`.** M-A1's HealthKit code must be wrapped in `#if canImport(HealthKit)` (exactly like the existing `#if canImport(WeatherKit)` block in `BiomeScanner.swift`), with the mock used where HealthKit is absent — otherwise CI's `swift test` job won't compile. Alternative: enable the iOS-Simulator job in `ci.yml` and gate on `xcodebuild test` instead.
- **Strict-concurrency will likely be red until M-A0 + the cross-cutting audit land** (FishingEngine still has `DispatchQueue.main.sync`, and the status docs disagree on the current warning count). Get it green first, then flip it to a required check. The `swift test` gate is safe to require immediately.
- **Squash-merge** keeps `main` one commit per milestone and easy to bisect.
