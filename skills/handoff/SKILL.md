---
name: handoff
description: Session close, test verification, and rolling log preservation skill
---

Before concluding any development session, run this `/handoff` closing process to preserve a rolling log window and ensure continuity for the next session:
1. Ensure all local functional changes have been fully committed to Git.
2. Update the rolling session log inside `docs/status/CURRENT.md` to maintain exactly a **two-session window**:
   - Rename the existing `## Last Session` heading to `## Previous Session`, overwriting or replacing any older previous session logs.
   - Delete any legacy session logs (such as `## Session X` or archives).
   - Write a fresh, detailed `## Last Session (Current)` section containing:
     - The explicit file paths modified this session.
     - A concise list of accomplishments.
     - What work remains uncompleted.
     - Actionable next steps for the incoming session.
     - Gotchas or concurrency warnings to look out for.
3. Run the XCTest suite via `swift test`. Verify that all 151 tests run and pass sequential validation with zero errors. Update the numbers in `docs/status/CURRENT.md` if any new tests were added.
4. Count the architectural decisions in `docs/DECISIONS.md` using `grep -c "^## D-" docs/DECISIONS.md`. Update the count in `docs/status/CURRENT.md` if new decisions were logged.
5. If the session introduced any new architectural decisions, describe their D-numbers and high-level context in the handoff.
6. Verify that state serialization logic retains the strict SHA-256 validation signatures (`session.json` + `session.json.sha256`) and AirPods motion manager utilizes correct battery-saving sample throttling.
7. Run the numbers validation: `/check-numbers`. Fix any detected stats drift before pushing.
