The `/pre-launch-checklist` command executes a suite of automated and manual-clear verification gates to ensure the Pod Monsters SDK is fully stable, compliant, and ready for release.

## Execution Workflow

When running the `/pre-launch-checklist` command, the agent must perform the following gates sequentially. This checklist does not auto-fix any issues; it only performs analysis and reports the final status of each gate, concluding with an overall status of `PASS`, `FAIL`, or `MANUAL`.

### Static Gates
Static gates are automated verifications run against the current codebase state.

1. **Secret Scanning Check**
   - **Command / Action**: Run `skills/check-numbers/scripts/secret_scan.sh`.
   - **Verification**: Ensure no credentials, API keys, or secrets exist in unstaged or staged files.
   - **Result Mapping**: If the secret scanner reports errors or exits with a non-zero status, this gate `FAIL`s.

2. **Unit Test Execution**
   - **Command / Action**: Run `swift test`.
   - **Verification**: Verify that all 151 unit tests pass successfully with zero failures.
   - **Result Mapping**: If any test fails or fewer than 151 tests run, this gate `FAIL`s.

3. **Strict Concurrency Check**
   - **Command / Action**: Run `swift build -Xswiftc -strict-concurrency=complete`.
   - **Verification**: Compile the package with complete strict concurrency checks enabled and verify that the build compiles successfully with zero Swift Concurrency warnings.
   - **Result Mapping**: If there are any concurrency warnings or build compilation errors, this gate `FAIL`s.

4. **Documentation Drift Check**
   - **Command / Action**: Run `skills/check-numbers/scripts/check_numbers.sh`.
   - **Verification**: Audit the codebase stats against the documented numbers in `docs/status/CURRENT.md` to prevent documentation drift.
   - **Result Mapping**: If the check numbers script reports freshness drift or exits with a non-zero status, this gate `FAIL`s.

---

### Dynamic Gates
Dynamic gates require checking runtime workspace status metadata and interactive verification.

1. **Launch Blockers Parsing**
   - **Command / Action**: Parse `/Users/stevendiaz/Pod monsters/docs/status/CURRENT.md` and scan for the `## Launch Blockers` section.
   - **Verification**: Locate every checklist line under `## Launch Blockers` that starts with or contains the red circle emoji (`🔴`).
   - **User Prompting**: 
     - Extract and present each of these blocking items as a mandatory manual-clear launch gate.
     - Prompt the user to resolve each blocking item and clear the `🔴` blocker from `docs/status/CURRENT.md` upon completion.
   - **Result Mapping**: If any unresolved item containing `🔴` exists in the `## Launch Blockers` section, this gate reports as `MANUAL`.

---

## Status Mapping & Reports

At the end of the execution, the agent must output a clear summary report with one of the following overall statuses:

- **`PASS`**: All **Static Gates** passed (zero secrets, all 151 unit tests passed, zero strict concurrency warnings, zero documentation drift), and the **Dynamic Gates** have no unresolved `🔴` launch blockers under `## Launch Blockers` in `docs/status/CURRENT.md`.
- **`FAIL`**: Any of the **Static Gates** failed (secret scanner detected secrets, any of the 151 unit tests failed, strict concurrency warnings exist, or documentation drift is detected).
- **`MANUAL`**: All **Static Gates** passed, but there is at least one unresolved `🔴` launch blocker under `## Launch Blockers` in `docs/status/CURRENT.md` requiring manual resolution and clearing.

The checklist does not attempt to automatically fix or modify files. It acts as an audit and gatekeeping tool to enforce release readiness.
