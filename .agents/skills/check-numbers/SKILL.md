---
name: check-numbers
description: Integrity and drift detection check skill for Pod Monsters stats
---

To perform a freshness audit and compare the documented stats in `docs/status/CURRENT.md` against actual codebase reality, execute these steps:
1. Run `swift test` and parse the console output:
   - Extract the total number of executed test cases and suites (the XCTest runner will print e.g. `Executed 151 tests, with 0 failures`).
   - Extract the total number of passing vs failing tests.
   - Compare these counts to the numbers documented under `## Numbers` in `docs/status/CURRENT.md`.
2. Count the architectural decisions:
   - Search `docs/DECISIONS.md` for header matching `## D-` (e.g. `grep -c "^## D-" docs/DECISIONS.md`).
   - Verify the decision count matches the decision count in `docs/status/CURRENT.md`.
3. Check the current active milestone:
   - Scan `docs/PROJECT.md` milestones table and compare the current active/done milestone states against `docs/status/CURRENT.md` "Milestone Status".
4. Persistence Hashing Verification:
   - Verify that any local `session.json` state saved in the environment is accompanied by a valid sibling `session.json.sha256` checksum signature. Validate that the signature correctly matches the hash of the JSON content.
5. AirPods Sample Throttling verification:
   - Ensure the `motionSampleInterval` constants in the motion manager files are set to standard throttling values and no Nan/Infinite coordinates are reported.
6. Report any drifted values. If there is a discrepancy between reality and `docs/status/CURRENT.md`, immediately report the drift and update `docs/status/CURRENT.md` with correct, verified numbers to maintain high-fidelity status reporting.

**Git Pre-Commit Hook Installation Guidelines:**
To automate this check and prevent committing drifted numbers to the git history, developers can register the `check_numbers.sh` script as a Git `pre-commit` hook:
1. Copy or link the helper script to your local git hooks folder:
   ```bash
   cp skills/check-numbers/scripts/check_numbers.sh .git/hooks/pre-commit
   ```
2. Make sure the hook script has executable permissions:
   ```bash
   chmod +x .git/hooks/pre-commit
   ```
3. Once registered, Git will automatically run the script before every commit. If the script detects a drift between the test run and `CURRENT.md`, the commit will be blocked, prompting you to update the status document first.

**Git Pre-Push Hook Installation Guidelines:**
To automate the checking of credentials and prevent leaking secrets into remote git history, developers can register the `secret_scan.sh` script as a Git `pre-push` or `pre-commit` hook:

- **Option A: Copying the script directly**
  1. Copy the secret scan script to your local git hooks folder:
     ```bash
     cp skills/check-numbers/scripts/secret_scan.sh .git/hooks/pre-push
     ```
  2. Make sure the hook script has executable permissions:
     ```bash
     chmod +x .git/hooks/pre-push
     ```

- **Option B: Symlinking the script (recommended for automatic updates)**
  1. Symlink the script to your local git hooks folder:
     ```bash
     ln -sf ../../skills/check-numbers/scripts/secret_scan.sh .git/hooks/pre-push
     ```
  2. Make sure the original script has executable permissions:
     ```bash
     chmod +x skills/check-numbers/scripts/secret_scan.sh
     ```

Once registered, Git will automatically run the script before every push (or commit if registered as `.git/hooks/pre-commit`). If any potential secret keys are detected in your staged changes or unpushed commits, the push/commit will be blocked, and the matching lines will be displayed.
