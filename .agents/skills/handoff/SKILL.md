---
name: handoff
description: Session close — append to a permanent history ledger, refresh the current snapshot, and verify numbers against reality (never against a hardcoded count).
---

# /handoff — Session Close
Run at the END of a session, AFTER the milestone's code is merged. Run it ONCE per milestone (not inside a build run) so the log gets exactly one entry per milestone.

Goal: leave an accurate snapshot of where things stand and a permanent record of what happened — without ever deleting past history.

Two files, two jobs:
*   `docs/status/HISTORY.md` — the permanent ledger. APPEND-ONLY. Never edit or delete past entries.
*   `docs/status/CURRENT.md` — the live snapshot. Safe to overwrite each time, because detail lives in `HISTORY.md`. This is what `/boot` and the next session read first, so keep it compact.

## Steps

1.  **Commit**: Ensure all of this session's changes are committed (on the merged branch / main, per `docs/WORKFLOW.md`).
2.  **Append to the history ledger — never truncate**:
    *   If `docs/status/HISTORY.md` does not exist, create it. First run only: if `CURRENT.md` currently holds session entries not yet in `HISTORY.md`, move them in first so nothing is lost. (Older entries already dropped by the previous skill can be recovered from `git log -p docs/status/CURRENT.md` — see the note at the bottom.)
    *   PREPEND one new entry at the top (newest first). Do NOT touch any existing entry:
        ```markdown
        ## <YYYY-MM-DD> — <milestone id / one-line summary>
        - Files: <explicit paths added or modified this session>
        - Done: <concise accomplishments>
        - Deferred: <what remains / known gaps>
        - Next: <actionable next steps for the incoming session>
        - Gotchas: <concurrency or other warnings>
        ```
        This file only grows. If it ever needs trimming, that's a separate manual decision — never automatic.
3.  **Refresh the snapshot (overwrite CURRENT.md)**: Replace its body with:
    *   **Stats** — passing test count, decisions count, current branch (real values from steps 4–5).
    *   **Latest session** — the full entry you just prepended to `HISTORY.md`.
    *   **Recent history** — a short index: just the dates + titles of the last ~3 `HISTORY.md` entries, no detail, pointing to `HISTORY.md`.
    *   **Next steps** — the immediate next actions.
    *   Keep the stat lines in the exact format `/check-numbers` greps for (so it still matches) — confirm against `check-numbers` if you change their wording.
4.  **Tests — record reality, never a fixed number**: Run `swift test`. Write the ACTUAL passing count it reports into `CURRENT.md`. Do NOT assert any specific total — the suite grows as milestones add tests; the only hard requirement is 0 failures.
5.  **Decisions count**: `grep -c "^## D-" docs/DECISIONS.md`; write that count into `CURRENT.md`. If the session introduced new decisions, note their D-numbers and one-line context in the latest entry.
6.  **Confirm no drift**: Run `/check-numbers`. It compares documented stats against reality. If it reports drift, the documentation is wrong — fix `CURRENT.md` to match reality, never the reverse. (Functional invariants like persistence integrity and motion-sampling behavior are guarded by the test suite in step 4, not by manual inspection here.)
7.  **Report**: State the new `HISTORY.md` entry's date/title, the test count, the decisions count, any new D-numbers, and the next steps.

---
*Note on recovering lost entries*: If older session logs were deleted and need to be backfilled into `docs/status/HISTORY.md`, they can be found by inspecting the history of `docs/status/CURRENT.md`:
```bash
git log -p -- docs/status/CURRENT.md
```
