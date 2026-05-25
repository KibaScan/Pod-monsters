# Pod Monsters

An Apple-native, concurrency-safe headless SDK (iOS 17+ / macOS 14+) for AirPods-driven fitness and gamification RPG.

---

## 🗺️ System Directory Map

This map outlines the repository's logical layout, detailing where to find and edit source code, tests, and configurations.

```
.
├── .gitignore               # Excludes Xcode builds, DerivedData, SPM caches, & local logs
├── Package.swift            # Swift Package Manager package declaration & dependencies
├── README.md                # [You are here] Central navigation & architectural entry point
├── Sources/                 # Application codebase
│   ├── PodMonstersApp.swift # Diagnostic host application entry point
│   ├── Core/                # Domain models, state machinery, & coordinator
│   │   ├── GameSession.swift    # Primary coordinator (@MainActor)
│   │   ├── Monster.swift        # Faction, Buddy evolution, & stats
│   │   └── Bait.swift           # Capturing tier & inventory representation
│   ├── Services/            # Sensor APIs, CoreMotion, & background timers
│   │   ├── AirPodsMotionManager.swift   # CMHeadphoneMotionManager wrapper
│   │   ├── BiomeScanner.swift          # GPS/Location, WiFi, & environment processing
│   │   ├── FishingEngine.swift         # Heart-rate-gated capture state machine
│   │   └── WorkoutRepRestManager.swift # Rep capture, durability, & pacing
│   └── Views/               # Swift UI premium diagnostic view layout
│       ├── BiomeView.swift          # Core Biome scanner dashboard
│       ├── DashboardView.swift      # Main navigation / aggregated views
│       ├── FactionButtonStyle.swift # Premium reusable button styling
│       ├── FishingView.swift        # Parasympathetic RPG fishing dashboard
│       ├── SniffModeView.swift      # Head-carriage motion & calibration radar
│       └── WorkoutView.swift        # Workout tracking dashboard
│
├── Tests/                   # Comprehensive unit and integration tests
│   └── PodMonstersTests/
│       ├── CoreTests.swift                  # Basic Core state tests
│       ├── BiomeTests.swift                 # Location & environmental scanning tests
│       ├── MotionTests.swift                # Calibrations, stillness, & threshold tests
│       ├── FishingTests.swift               # Gated capture & parasympathetic shift tests
│       ├── WorkoutTests.swift               # Rep scoring, pacing, & rest tests
│       ├── GameSessionTests.swift           # Main coordinator loop & evolutionary tests
│       ├── GameSessionPersistenceTests.swift# JSON state persistence & SHA-256 validation tests
│       ├── DashboardViewTests.swift         # View instantiation/binding verification
│       ├── Milestone4Tests.swift            # Throttling, battery guards, & NaN protections
│       └── AdversarialTests.swift           # State injection, thread-safety, & tamper resistance
│
└── docs/                    # Architectural specs, audits, and original requirements
    ├── PROJECT.md            # Concurrency Milestones, contracts, and code layout overview
    ├── UI_AUDIT_REPORT.md    # Principles (Glassmorphism, Springs, Haptics) to SwiftUI modifiers mapping
    ├── phase_0_summary.md    # Initial phase evaluation and implementation recap
    ├── pod-monsters-concept.md        # Comprehensive game design, lore, and gameplay mechanisms
    ├── pod-monsters-asset-pipeline.md # Detailed specification of assets and pipeline pipeline
    ├── pod-monsters-m5-review.md      # Summary of Milestone 5 regression, auditing, and deliverables
    └── ORIGINAL_REQUEST.md   # The original source prompt and requirements for Pod Monsters
```

---

## 🏛️ Architectural Overview

Pod Monsters utilizes a strictly **concurrency-safe, Actor-isolated design** targeting Swift 5.9 concurrency models.

```mermaid
graph TD
    subgraph Core [@MainActor]
        GS[GameSession]
        M[Monster / Faction State]
        B[Bait / Inventory]
    end
    
    subgraph Services [@MainActor]
        AMM[AirPodsMotionManager]
        BS[BiomeScanner]
        FE[FishingEngine]
        WRM[WorkoutRepRestManager]
    end
    
    subgraph Views [SwiftUI @MainActor]
        DV[DashboardView]
        BV[BiomeView]
        FV[FishingView]
        SMV[SniffModeView]
        WV[WorkoutView]
    end

    %% Bindings & Actions
    DV --> BV & FV & SMV & WV
    DV -.-> |Observable / Bindings| GS
    GS --> AMM & BS & FE & WRM
    AMM & BS -.-> |Delegate Callbacks| GS
    FE & WRM -.-> |Delegate Callbacks| GS
```

### Main Coordinator (`GameSession`)
- Isolates all state modifications on the `@MainActor` to prevent race conditions.
- Coordinates incoming events from hardware/location services.
- Controls buddy leveling, experience distribution, and triggers evolution checks.
- Manages secure **JSON State Persistence** reinforced with **SHA-256 anti-tamper signatures** (`session.json` + `session.json.sha256`).

### Sensor & Background Engines
1. **`AirPodsMotionManager`**: Harnesses `CMHeadphoneMotionManager` to compute absolute head carriage pitch, stillness indexes, and yaw calibration deltas. Safe-guarded against infinite/NaN readings and includes sensor rate-throttling to save battery.
2. **`WorkoutRepRestManager`**: Evaluates active rep pacing, motion consistency, and automatically transitions between Lift Set and Rest capture states based on user durability.
3. **`FishingEngine`**: A state-machine driving deep parasympathetic breathing RPG captures. Requires head stillness and calibrated breathing profiles to trigger successful buddy captures.
4. **`BiomeScanner`**: Simulates and resolves the active biome (e.g. Urban, Forest, Aquatic) using combined GPS signals and Wi-Fi SSID counts.

---

## 📚 Documentation Index

Direct links to essential files for rapid reference:

| File | Purpose / Description |
| :--- | :--- |
| 📋 [PROJECT.md](docs/PROJECT.md) | High-level roadmap tracking Concurrency modernization, evolutionary systems, anti-tamper security, and interface contracts. |
| 🎨 [UI_AUDIT_REPORT.md](docs/UI_AUDIT_REPORT.md) | Architectural details mapping design principles (Glassmorphism, Tactile Springs, Perceptual Colors, Haptic Feedback) to SwiftUI implementation. |
| 📖 [Concept Specification](docs/pod-monsters-concept.md) | Comprehensive gameplay document detailing faction lore, Biome modifiers, fishing mini-games, and core gamification loops. |
| ⚙️ [Asset Pipeline](docs/pod-monsters-asset-pipeline.md) | Resource management details, sound triggers, and image assets metadata guidelines. |
| 📝 [M5 Review Summary](docs/pod-monsters-m5-review.md) | High-fidelity evaluation of the test suite, coverage, concurrency audits, and regression tests. |
| 🕰️ [Phase 0 Summary](docs/phase_0_summary.md) | Review of initial implementation decisions and fundamental SDK designs. |
| 🧩 [Original Request](docs/ORIGINAL_REQUEST.md) | The raw, unredacted initial project request containing the comprehensive design prompt. |

---

## 🛠️ Developer Commands

Compile and test this package directly from the command line:

### 1. Build the Package
```bash
swift build
```

### 2. Run the Entire Test Suite
```bash
swift test
```

### 3. Run Specific Tests
```bash
swift test --filter PodMonstersTests.AdversarialTests
```
