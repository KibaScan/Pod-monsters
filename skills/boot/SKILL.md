---
name: boot
description: Workspace initialization and context briefing skill for Pod Monsters SDK
---

Before starting ANY work on the Pod Monsters Swift SDK:
1. Run `git status` via terminal to check if the workspace is clean. If there are uncommitted changes, commit or stash them first to establish a safe rollback point.
2. Read the following reference documents in order to recover context from a zero-knowledge state:
   - `GEMINI.md` in project root (SPM build/test commands, strict concurrency, and style guidelines).
   - `docs/DECISIONS.md` (active architectural decisions D-01 through D-04, scanning for anything affecting current work).
   - `docs/PROJECT.md` (overall project architecture, milestone tracking, and interface contracts).
   - `docs/status/CURRENT.md` (rolling session log and current test numbers).
3. Analyze and report to the coordinator or user:
   - What milestone we are currently executing and its exact scope.
   - What components are completed, what is actively in progress, and what is currently broken or needing attention.
   - Which architectural decisions (from `docs/DECISIONS.md`) constrain or direct the current implementation tasks.
   - What concrete next steps we should take.
   - Validate if the logged statistics in `docs/status/CURRENT.md` (total test cases, passing/failing tests, decision count) match the actual environment (run `/check-numbers` to verify).
