# Pod Monsters SDK: Architectural Decisions Log

## D-01: Concurrency Isolation (Main Actor)
- **Status**: Accepted
- **Context**: Pod Monsters coordinates sensor input, workout rep scoring, and UI game status updates. Direct multi-threaded mutations and synchronous queue hopping led to deadlocks or thread unsafety.
- **Decision**: Remove manual locks (`NSLock`, `inventoryLock`) and legacy synchronous main actor hops. Enforce full isolation of `GameSession`, `AirPodsMotionManager`, and related delegate protocols onto the `@MainActor`. Use native Swift async/await structures for cooperative multitasking.

## D-02: Evolution Loop (Dynamic starter species mutation)
- **Status**: Accepted
- **Context**: Budding starter monsters need to grow and evolve dynamically without manual controller checking.
- **Decision**: Integrate `checkEvolution()` directly into the XP drip flow (`addXPToBuddy()`). Starters (Zephyr, Basalt, Lumina) evolve past level thresholds dynamically based on training activity distributions, and atomically save state and broadcast observers via notifications.

## D-03: SHA-256 Anti-Tamper Persistence
- **Status**: Accepted
- **Context**: Local JSON game state file `session.json` is highly vulnerable to user-side injection edits.
- **Decision**: Compute a secure hex-encoded SHA-256 signature of the state using CryptoKit during auto-saves. Write it to a sibling `session.json.sha256` validation file. Verify signature matching on cold boots, and reject tampered saves with a serialization error to enforce client-side integrity.

## D-04: Sensor Frequency Throttling & Battery Safeguards
- **Status**: Accepted
- **Context**: Raw headphones attitude motion streaming consumes excessive battery and generates high signal noise.
- **Decision**: Implement a centralized `motionSampleInterval` logic in `AirPodsMotionManager`. Throttling bounds attitude processing rates, and adds safe unwraps/infinite protection checks on attitude calibration deltas inside standard `[-180, 180]` boundaries.

## D-05: Naming & Vocabulary (Podmon / Pod-dex)
- **Status**: Accepted
- **Context**: The codebase and user interface were using inconsistent terms like "Monster", "buddy", and "familiar" to refer to the companion creatures.
- **Decision**: Standardize on the term **Podmon** (singular) and **Podmons** (plural). The Swift code type is named `Podmon`. User-facing copy will exclusively use "Podmon" / "Podmons". The collection screen is named the **Pod-dex**. Milestone M-A0.5 will perform a global refactor to rename `Monster` → `Podmon` and all "buddy"/"monster" terminology to "Podmon" / "Podmons" across sources and tests.

