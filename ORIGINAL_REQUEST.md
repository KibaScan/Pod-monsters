# Original User Request

## Initial Request — 2026-05-21T05:15:49Z

# Teamwork Project Prompt — Draft

Audit the Pod Monsters Swift SDK codebase. Identify all existing SwiftUI diagnostic views and upgrade them by translating the premium Web principles from the `frontend-ui-design` skill (perceptually uniform colors, glassmorphism, fluid scaling, tactile spring animations) into native iOS 17+ SwiftUI equivalents.

Working directory: /Users/stevendiaz/Pod monsters
Integrity mode: development

## Requirements

### R1. SwiftUI Native Translation
Audit the codebase for SwiftUI views and upgrade their design system. You must translate the SOTA web principles into valid iOS 17+ SwiftUI modifiers (e.g., using `.background(.ultraThinMaterial)` for glassmorphism, native Apple `.spring()` animations for tactile feedback, and perceptual color mapping for OKLCH guidelines). Do not hallucinate CSS modifiers in Swift code.

### R2. Architectural Safety
The UI upgrades must be purely cosmetic. You must not alter the underlying business logic, state management (`@Published` behavior), or persistence mechanisms. 

### R3. Reasoning Documentation
Generate a `UI_AUDIT_REPORT.md` documenting every view modified, mapping the original `frontend-ui-design` web principle to the specific SwiftUI modifier you chose, and explaining the reasoning behind the adaptation.

## Acceptance Criteria

### Objective Verification
- [ ] **Compilation Check**: The entire Pod Monsters SDK must compile successfully without warnings or errors after the UI modifications.
- [ ] **Test Integrity**: All 146 existing unit tests in the project must run and pass sequentially (`swift test`), proving no core logic was damaged.
- [ ] **No Hallucinations**: The `UI_AUDIT_REPORT.md` is generated and specifically cites valid SwiftUI APIs matching the requested design principles.

## Follow-up — 2026-05-26T15:51:05Z

Analyze the raw text instructions in the `commands/` directory, strip out all obsolete references to the JS/Jest/Supabase "Kiba" project, and migrate them into structured, fully-compatible Antigravity Skill modules under a new root `skills/` folder customized for the Pod Monsters Swift package, supporting the `/boot`, `/handoff`, and subagent PR review workflows.

Working directory: `/Users/stevendiaz/Pod monsters`
Integrity mode: development

## Requirements

### R1. Skill Restructuring & Frontmatter Optimization
Translate the 6 obsolete text command files in `commands/` into 5 unified, highly-optimized Antigravity Skill folders under a new root `skills/` folder:
- **`skills/boot/`**: Workspace initialization and context briefing skill, triggered at the start of a session (e.g. by `/boot`).
- **`skills/check-numbers/`**: Integrity and drift detection check skill.
- **`skills/code-review/`**: Swift Pull Request concurrency, `@MainActor` isolation, and thread-safety audit checklist, designed for subagent code review swarms.
- **`skills/handoff/`**: Session close and rolling log preservation skill, triggered at the end of a session (e.g. by `/handoff`).
- **`skills/milestone-close/`**: Comprehensive milestone validation and progression closeout skill.

Each skill folder must contain a required `SKILL.md` containing:
- YAML frontmatter with `name` and `description`.
- Detailed, clean markdown instructions that are 100% compatible with Pod Monsters.

### R2. Codebase Adaptation & Command Translation
Strip all references to the JavaScript environment, `npx jest`, Supabase migrations, and pet food brands. Replace them with native Pod Monsters Swift equivalents:
- Replace `npx jest` and Jest test assertions with `swift test` parsing and Swift PM command guidelines.
- Replace Supabase SQL migration files checking with Swift package target checks or database-free status tracking.
- Redesign the checklist rules to verify Swift Concurrency `@MainActor` rules, local `session.json` + `session.json.sha256` persistence validation, and AirPods sample throttling.

### R3. Reference State Document Initialization
To provide functional targets for the migrated skills, initialize the following missing status documents in the workspace:
- **`GEMINI.md`** (in root): Workspace guidelines, build (`swift build`), test (`swift test`), coding style, strict concurrency compilation recommendations (`-strict-concurrency=complete`), and Xcode-specific simulator testing guidelines (`xcodebuild test`).
- **`docs/status/CURRENT.md`**: Rolling session log structure, current milestone status, and numbers (e.g. 151 tests, 0 failures, 4 architectural decisions).
- **`docs/DECISIONS.md`**: Architectural decisions log documenting `D-01` (Concurrency Isolation), `D-02` (Evolution Loop), `D-03` (SHA-256 Anti-Tamper persistence), and `D-04` (Sensor Frequency Throttling).

### R4. Automated Freshness Scripting & Git Hooks
Implement a lightweight, executable bash helper script in `skills/check-numbers/scripts/check_numbers.sh` that:
- Runs `swift test` and extracts the total count of executed, passed, and failed test cases.
- Counts the number of active decision headers (`D-XX`) in `docs/DECISIONS.md`.
- Compares these counted values against the documented stats in `docs/status/CURRENT.md`, and exits with an error code if drift is detected.
- Includes clear guidelines in `skills/check-numbers/SKILL.md` explaining how developers can register this script as a Git `pre-commit` hook (in `.git/hooks/pre-commit`) to prevent committing drifted numbers.

### R5. Obsolete Resource Cleanup [DELETE]
- Once all skills have been successfully created and verified, **completely delete the old `commands/` directory** and its contents to maintain a clean, high-signal project workspace.

## Acceptance Criteria

### Skill Structure Validity
- [ ] A root `skills/` folder is created containing subfolders `boot/`, `check-numbers/`, `code-review/`, `handoff/`, and `milestone-close/`.
- [ ] Each subfolder has a valid `SKILL.md` with properly formatted YAML frontmatter (name, description).
- [ ] There are **zero** occurrences of JS dependencies, `jest`, `supabase`, `migrations`, or references to "Kiba" anywhere in the new skills.

### Reference Document Compliance
- [ ] `GEMINI.md` is initialized in the project root with accurate Swift build/test and concurrency guidelines.
- [ ] `docs/status/CURRENT.md` and `docs/DECISIONS.md` exist and reflect the real Pod Monsters test count (151) and Phase 0 decisions.

### Script Execution & Git Hook Guide
- [ ] The `check_numbers.sh` script compiles and runs cleanly in the shell.
- [ ] The script accurately parses `swift test` output and successfully validates current test and decision counts without throwing false alarms.
- [ ] `skills/check-numbers/SKILL.md` provides clear copy-paste commands for installing the script as a Git pre-commit hook.

### Workspace Cleanup
- [ ] The obsolete `/Users/stevendiaz/Pod monsters/commands` folder is deleted.

## Follow-up — 2026-05-26T16:16:18Z

Implement a secure, hybrid Pre-Launch Checklist skill (`/pre-launch-checklist`), an automated Pre-Push Git Hook secret scanner, and a root-level `mcp.json` configuration for the Pod Monsters SDK codebase.

Working directory: `/Users/stevendiaz/Pod monsters`
Integrity mode: development

## Requirements

### R1. Pre-Launch Checklist Skill (`skills/pre-launch-checklist/`)
Create a new custom Antigravity Skill folder under `skills/pre-launch-checklist/` containing a required `SKILL.md` that:
- Defines the `/pre-launch-checklist` command to run pre-release gates.
- **Static Gates:**
  1. Executes the secret scanner script (to ensure no credentials exist in unstaged or staged files).
  2. Runs `swift test` and verifies all 151 unit tests pass with zero failures.
  3. Executes `swift build -Xswiftc -strict-concurrency=complete` and verifies zero Swift Concurrency warnings.
  4. Runs `skills/check-numbers/scripts/check_numbers.sh` to ensure no documentation drift.
- **Dynamic Gates:**
  1. Parses [docs/status/CURRENT.md](file:///Users/stevendiaz/Pod%20monsters/docs/status/CURRENT.md) under a new `## Launch Blockers` section.
  2. Any line starting with a `🔴` is extracted and presented as a mandatory, manual-clear launching gate.
  3. Prompts the user to resolve each blocking item and clear them from `CURRENT.md` upon completion.
- Does not auto-fix anything; reports status clearly as `PASS`, `FAIL`, or `MANUAL`.

### R2. Automated Pre-Push Secret Scanner Hook
Develop an executable shell script at `skills/check-numbers/scripts/secret_scan.sh` that:
- Runs `git diff` on staged changes and scans commits for standard secret prefixes (e.g. `sk-`, `sb_secret`, `AIza`, `AKIA`).
- Exits with a non-zero code if any pattern matches, preventing git operations.
- Integrates comprehensive guidelines in `skills/check-numbers/SKILL.md` detailing how to symlink or copy this script into `.git/hooks/pre-push` or `.git/hooks/pre-commit` for local developers.

### R3. Project-Scoped MCP Configuration
Create a project-scoped `mcp.json` in the root of the workspace to configure environment tools and third-party APIs. It must define baseline structures for:
- Local weather mock services (required for simulating biomes and precipitation).
- Headphone motion coordinate generators (supporting AirPods simulation inputs).
Ensure it is clean, documented, and structured so it travels with the codebase when checked out in new environments.

## Acceptance Criteria

### Skill & Hook Deployment
- [ ] A root `skills/pre-launch-checklist/` folder exists containing a valid `SKILL.md` with properly formatted YAML frontmatter.
- [ ] The `secret_scan.sh` script exists, is executable (`chmod +x`), and exits with `1` when simulated secret patterns are injected into staged git diffs.
- [ ] Clear guidelines for symlinking the script to `.git/hooks/pre-push` are documented in `skills/check-numbers/SKILL.md`.

### Dynamic Checklist Parsing
- [ ] Creating a dummy entry like `- 🔴 Rotate test API key` in `docs/status/CURRENT.md` under `## Launch Blockers` is successfully detected at runtime and surfaced as a blocking manual gate.
- [ ] When the `🔴` entry is removed, the checklist passes.

### Workspace Configuration
- [ ] A valid `mcp.json` exists in the workspace root documenting mock weather and CoreMotion tool pipelines.
- [ ] Running `./skills/check-numbers/scripts/check_numbers.sh` succeeds with zero errors.
