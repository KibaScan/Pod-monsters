To officially close a project milestone and transition to the next step, execute this checklist:
1. Run the entire XCTest suite: `swift test`. Report the exact test count, suite list, and confirm 0 failures.
2. Run `/check-numbers` to guarantee zero drift between the code state and `docs/status/CURRENT.md`.
3. Update `docs/status/CURRENT.md` with the new project state:
   - Move the active milestone in the "Milestone Status" checklist to `DONE`.
   - Update what works, what is broken, and aggregate numbers.
4. Create a dedicated closeout document at `docs/status/milestones/[MilestoneName].md` detailing:
   - What was accomplished and built.
   - Key architectural decisions made (with links to `D-XX` numbers in `docs/DECISIONS.md`).
   - Tech debt introduced or remaining items to harden.
   - Detailed test coverage summary (XCTest execution counts, suite list, duration).
5. Update `GEMINI.md` if any environment variables, Swift compiler configurations, strict-concurrency settings, or testing guidelines changed structurally.
6. If any new runtime error patterns or Swift serialization/concurrency exceptions were uncovered, document them in `docs/errors.md` (or relevant references).
7. Review if any new lessons learned should be registered as non-negotiable workspace rules inside `GEMINI.md`.
8. Update `docs/PROJECT.md`: mark the milestone status as `DONE`, record its conversation ID, and note any changes in interface contracts or code layout.
