import XCTest
import CoreLocation
@testable import PodMonsters

@MainActor
final class GameSessionTests: XCTestCase {
    
    // MARK: - F7 Tier 1
    
    func testT1_F7_01_SessionInitialization() {
        let session = GameSession()
        XCTAssertNotNil(session.motionManager)
        XCTAssertNotNil(session.biomeScanner)
        XCTAssertNotNil(session.fishingEngine)
        XCTAssertNotNil(session.workoutManager)
        XCTAssertNil(session.equippedPodmon)
        XCTAssertEqual(session.baitInventory[.ironHooks], 5)
    }
    
    func testT1_F7_02_EquippedPodmonTracking() {
        let session = GameSession()
        let podmon = Podmon(name: "Zephyr", faction: .kinetic)
        session.equippedPodmon = podmon
        
        session.workoutManager.startWorkout()
        session.performWorkoutRep(quality: 1.0)
        XCTAssertGreaterThan(session.equippedPodmon?.xp ?? 0, 0.0)
    }
    
    func testT1_F7_03_UIBindingUpdates() {
        let session = GameSession()
        
        let expectation = self.expectation(description: "UI binding update")
        
        let cancellable = session.fishingEngine.$currentState.sink { state in
            if state == .waiting {
                expectation.fulfill()
            }
        }
        
        try? session.castFishingLine(bait: .spinnerLures)
        session.fishingEngine.simulateTick()
        
        waitForExpectations(timeout: 1.0)
        cancellable.cancel()
    }
    
    func testT1_F7_04_PostureDripAccumulation() {
        let session = GameSession()
        let podmon = Podmon(name: "Zephyr", faction: .kinetic)
        session.equippedPodmon = podmon
        
        // Calibration delta updates DO NOT trigger posture XP drips anymore
        session.motionManager(session.motionManager, didUpdateCalibrationDelta: 0.0, pitchDelta: 5.0)
        XCTAssertEqual(session.equippedPodmon?.xp ?? 0.0, 0.0)
        
        // Reference reset calls (e.g. calibrateReferenceAngle()) DO NOT trigger posture XP drips anymore
        session.motionManager.calibrateReferenceAngle()
        XCTAssertEqual(session.equippedPodmon?.xp ?? 0.0, 0.0)
        
        // Good posture (pitch 5.0) -> drips XP
        session.motionManager(session.motionManager, didUpdateHeadCarriage: 5.0)
        XCTAssertGreaterThan(session.equippedPodmon?.xp ?? 0, 0.0)
    }
    
    func testT1_F7_05_ReleasePodmonXPBoost() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Zephyr", faction: .kinetic)
        
        let wild = Podmon(name: "Wild Basalt", faction: .forge)
        session.capturedPodmons.append(wild)
        XCTAssertNoThrow(try session.releasePodmon(wild))
        
        // Essence routes 500 XP to active podmon!
        XCTAssertEqual(session.equippedPodmon?.level, 6) // flat 100 XP per level: 500 XP brings level from 1 to 6
    }
    
    // MARK: - F7 Tier 2
    
    func testT2_F7_01_EmptyGameSession() {
        let session = GameSession()
        
        // Actions that require equipped podmon should throw or fail gracefully
        let wild = Podmon(name: "Wild Basalt", faction: .forge)
        XCTAssertThrowsError(try session.releasePodmon(wild)) { error in
            XCTAssertEqual(error as? SessionError, .noPodmonEquipped)
        }
    }
    
    func testT2_F7_02_ExtremePostureDeviations() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Zephyr", faction: .kinetic)
        
        // Extreme posture (pitch 50.0) -> no drip
        session.motionManager(session.motionManager, didUpdateHeadCarriage: 50.0)
        XCTAssertEqual(session.equippedPodmon?.xp, 0.0)
    }
    
    func testT2_F7_03_DualActiveWorkouts() {
        let session = GameSession()
        
        // Start active strength set
        session.workoutManager.startWorkout()
        XCTAssertEqual(session.workoutManager.currentState, .activeSet)
        
        // Banned from casting line during active lifting set
        XCTAssertThrowsError(try session.castFishingLine(bait: .spinnerLures)) { error in
            XCTAssertEqual(error as? SessionError, .activeWorkoutConflict)
        }
    }
    
    func testT2_F7_04_FastSessionSaveRestore() {
        let session = GameSession()
        session.isSubscriber = true
        session.equippedPodmon = Podmon(name: "Lumina", faction: .aether)
        session.baitInventory[.ironHooks] = 12
        
        let data = session.saveState()
        XCTAssertNotNil(data)
        
        let newSession = GameSession()
        XCTAssertNoThrow(try newSession.restoreState(from: data))
        
        XCTAssertEqual(newSession.equippedPodmon?.name, "Lumina")
        XCTAssertEqual(newSession.baitInventory[.ironHooks], 12)
        XCTAssertTrue(newSession.isSubscriber)
    }
    
    func testT2_F7_05_BackgroundTaskInterruption() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Zephyr", faction: .kinetic)
        session.baitInventory[.ironHooks] = 20
        
        session.appDidEnterBackground()
        
        // Modify session state in background (simulated)
        session.equippedPodmon = nil
        
        // Restore
        session.appWillEnterForeground()
        
        XCTAssertEqual(session.equippedPodmon?.name, "Zephyr")
        XCTAssertEqual(session.baitInventory[.ironHooks], 20)
    }
    
    // MARK: - Tier 3 Combinations
    
    func testT3_COMB_01_StrengthToFishingBaitCycle() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Basalt", faction: .forge)
        session.baitInventory[.ironHooks] = 0
        
        // Complete strength reps and crack shield
        session.workoutManager.startWorkout()
        
        // Wait and perform reps
        let now = Date()
        session.workoutManager.performRep(quality: 1.0, duration: 2.0, at: now.addingTimeInterval(-4.0))
        session.workoutManager.performRep(quality: 1.0, duration: 2.0, at: now.addingTimeInterval(-3.0))
        session.workoutManager.performRep(quality: 1.0, duration: 2.0, at: now.addingTimeInterval(-2.0))
        session.workoutManager.performRep(quality: 1.0, duration: 2.0, at: now.addingTimeInterval(-1.0))
        session.workoutManager.performRep(quality: 1.0, duration: 2.0, at: now) // shield cracked!
        
        XCTAssertEqual(session.workoutManager.shieldDurability, 0.0)
        
        // Earn Iron Hook bait from cracked shield
        try? session.addBait(.ironHooks, count: 1)
        XCTAssertEqual(session.baitInventory[.ironHooks], 1)
        
        // End workout and start rest period
        session.workoutManager.startRestPeriod()
        
        // Cast earned bait
        XCTAssertNoThrow(try session.castFishingLine(bait: .ironHooks))
        session.fishingEngine.simulateTick()
        XCTAssertEqual(session.baitInventory[.ironHooks], 0)
        XCTAssertEqual(session.fishingEngine.currentState, .waiting)
    }
    
    func testT3_COMB_02_CardioToFishingBaitCycle() async {
        let session = GameSession()
        session.baitInventory[.spinnerLures] = 0
        
        // Perform scan in water biome
        session.biomeScanner.mockOverpassResponse = "{\"tags\": {\"natural\": \"water\"}}"
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let state = try? await session.biomeScanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state?.type, .water)
        
        // Earned bait from walking/cardio milestone
        try? session.addBait(.spinnerLures, count: 1)
        
        // Verify bait is castable in this session
        XCTAssertNoThrow(try session.castFishingLine(bait: .spinnerLures))
    }
    
    func testT3_COMB_03_SniffModeCalibrationInActiveBiome() async {
        let session = GameSession()
        
        // Start active biome scan
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        _ = try? await session.biomeScanner.scanCurrentLocation(coordinate: coord)
        
        // Calibrate head position using AirPodsMotionManager
        session.motionManager.startTracking()
        session.motionManager.calibrateReferenceAngle()
        session.motionManager.simulateHeadMovement(yaw: 0.0, pitch: 0.0)
        
        XCTAssertEqual(session.motionManager.calibrationDelta.yaw, 0.0)
        XCTAssertEqual(session.motionManager.calibrationDelta.pitch, 0.0)
    }
    
    func testT3_COMB_04_MeditationHRVGatedFishingPatience() {
        let session = GameSession()
        try? session.castFishingLine(bait: .mindBeads)
        session.fishingEngine.simulateTick()
        
        // Verify waiting phase
        XCTAssertEqual(session.fishingEngine.currentState, .waiting)
        
        // Feed mock high stillness from AirPods to extend patience window
        session.motionManager.startTracking()
        session.motionManager.feedMicroMovements(magnitude: 0.01) // high stillness: score 0.99
        XCTAssertEqual(session.motionManager.stillnessScore, 0.99)
        
        // Trigger bite safely
        session.fishingEngine.triggerBite()
        XCTAssertEqual(session.fishingEngine.currentState, .biting)
    }
    
    func testT3_COMB_05_TaiChiReelBreathAlignment() {
        let session = GameSession()
        try? session.castFishingLine(bait: .spinnerLures)
        session.fishingEngine.simulateTick()
        session.fishingEngine.triggerBite()
        session.fishingEngine.setHook()
        
        // Reeling
        XCTAssertEqual(session.fishingEngine.currentState, .reeling)
        
        // Track high stillness micro-movements
        session.motionManager.startTracking()
        session.motionManager.feedMicroMovements(magnitude: 0.02)
        XCTAssertEqual(session.motionManager.stillnessScore, 0.98)
        
        // Synchronized breathing rate at 6.0 breaths/min decreases tension
        session.fishingEngine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertEqual(session.fishingEngine.lineTension, 0.15) // drops from 0.3 to 0.15
    }
    
    func testT3_COMB_06_ShieldCrackAndRestCapture() {
        let session = GameSession()
        session.workoutManager.startWorkout()
        
        // Crack shield
        session.workoutManager.shieldDurability = 0.0
        session.workoutManager.startRestPeriod()
        
        // During Rest Capture, spawn the target podmon
        XCTAssertEqual(session.workoutManager.currentState, .restCapture)
        
        let target = Podmon(name: "Basalt Sprite", faction: .forge)
        session.capturedPodmons.append(target)
        XCTAssertEqual(session.capturedPodmons.count, 1)
    }
    
    func testT3_COMB_07_MulticomponentGameSessionSave() {
        let session = GameSession()
        var starter = Podmon(name: "Zephyr", faction: .kinetic)
        starter.addXP(4500.0, activityType: .kinetic)
        let evolved = starter.checkEvolution()
        session.equippedPodmon = evolved
        
        try? session.useBait(.ironHooks) // spend 1 iron hook
        
        let data = session.saveState()
        
        let restoredSession = GameSession()
        try? restoredSession.restoreState(from: data)
        
        XCTAssertEqual(restoredSession.equippedPodmon?.name, "Evolved Zephyr")
        XCTAssertEqual(restoredSession.baitInventory[.ironHooks], 4)
    }
    
    // MARK: - Tier 4 Scenarios
    
    func testT4_SCEN_01_CompleteWalkAndCaptureRoutine() async {
        let session = GameSession()
        let podmon = Podmon(name: "Zephyr", faction: .kinetic)
        session.equippedPodmon = podmon
        
        // Step 1: Walk registered at 145 steps/min -> add Kinetic XP
        session.equippedPodmon?.addXP(100.0, activityType: .kinetic)
        
        // Step 2: Biome Scanner triggers and parses a greenSpace biome
        session.biomeScanner.mockOverpassResponse = "{\"tags\": {\"leisure\": \"park\"}}"
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let state = try? await session.biomeScanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state?.type, .greenSpace)
        
        // Step 3: Sniff Mode locks head coordinate
        session.motionManager.startTracking()
        session.motionManager.calibrateReferenceAngle()
        session.motionManager.simulateHeadMovement(yaw: 0.0, pitch: 0.0)
        
        // Step 4: Perform pinch-and-flick gesture to capture
        let expectation = self.expectation(description: "Pinch flick capture")
        session.motionManager.onGestureDetected = { gesture in
            XCTAssertEqual(gesture, "pinch-and-flick")
            let captured = Podmon(name: "Wild Zephyr", faction: .kinetic)
            session.capturedPodmons.append(captured)
            session.equippedPodmon?.addXP(50.0, activityType: .kinetic)
            expectation.fulfill()
        }
        session.motionManager.simulateGesture("pinch-and-flick")
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(session.capturedPodmons.count, 1)
        XCTAssertGreaterThan(session.equippedPodmon?.xp ?? 0, 0.0)
    }
    
    func testT4_SCEN_02_BarbellStrengthWorkoutAndRestCapture() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Basalt", faction: .forge)
        
        // Step 1: Start strength session
        session.workoutManager.startWorkout()
        
        // Step 2: Perform 10 reps to crack shield
        session.workoutManager.shieldDurability = 0.0
        XCTAssertEqual(session.workoutManager.shieldDurability, 0.0)
        
        // Step 3: Transition to Rest period
        session.workoutManager.startRestPeriod()
        XCTAssertEqual(session.workoutManager.currentState, .restCapture)
        
        // Step 4: Perform cradle gesture to capture
        let captured = Podmon(name: "Forge Sprite", faction: .forge)
        session.capturedPodmons.append(captured)
        session.equippedPodmon?.addXP(100.0, activityType: .forge)
        
        XCTAssertEqual(session.capturedPodmons.count, 1)
        XCTAssertEqual(session.equippedPodmon?.level, 2)
    }
    
    func testT4_SCEN_03_DeepMeditationAndEtherealSpiritBonding() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Lumina", faction: .aether)
        
        // Step 1: Start mindful session, check high stillness score
        session.motionManager.startTracking()
        session.motionManager.feedMicroMovements(magnitude: 0.01) // 0.99 stillness
        XCTAssertGreaterThan(session.motionManager.stillnessScore, 0.95)
        
        // Step 2: Synchronize breathing rate at 6.0 breaths/min
        session.fishingEngine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertEqual(session.fishingEngine.breathPaceMatchScore, 1.0)
        
        // Step 3: Capture Ethereal spirit
        let spirit = Podmon(name: "Aether Spirit", faction: .aether)
        session.capturedPodmons.append(spirit)
        session.equippedPodmon?.addXP(150.0, activityType: .aether)
        
        XCTAssertEqual(session.capturedPodmons.count, 1)
        XCTAssertGreaterThan(session.equippedPodmon?.xp ?? 0.0, 0.0)
    }
    
    func testT4_SCEN_04_MeditativeWeekendFishingTrip() async {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Lumina", faction: .aether)
        
        // Step 1: Travel to lake, scan water biome at dusk
        session.biomeScanner.mockOverpassResponse = "{\"tags\": {\"natural\": \"water\"}}"
        
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 20
        components.hour = 18 // Equator 18:00 UTC is Dusk
        components.minute = 0
        
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        session.biomeScanner.mockTime = utcCalendar.date(from: components)!
        
        let state = try? await session.biomeScanner.scanCurrentLocation(coordinate: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0))
        XCTAssertEqual(state?.type, .water)
        XCTAssertEqual(state?.solarPeriod, .dusk)
        
        // Step 2: Select Mind Bead bait and cast
        XCTAssertNoThrow(try session.castFishingLine(bait: .mindBeads))
        session.fishingEngine.simulateTick()
        XCTAssertEqual(session.fishingEngine.currentState, .waiting)
        
        // Step 3: Trigger bite and set hook
        session.fishingEngine.triggerBite()
        session.fishingEngine.setHook()
        XCTAssertEqual(session.fishingEngine.currentState, .reeling)
        
        // Step 4: Tai-Chi reel: match breathing to reduce tension and capture
        session.fishingEngine.updateBreathingTempo(simulatedRate: 6.0)
        session.fishingEngine.reelIn()
        
        XCTAssertEqual(session.fishingEngine.currentState, .captured)
        XCTAssertEqual(session.capturedPodmons.count, 1)
    }
    
    func testT4_SCEN_05_TempestStormPuddleFishingEvent() {
        let session = GameSession()
        session.equippedPodmon = Podmon(name: "Zephyr", faction: .kinetic)
        
        // Step 1: Active rain/tempest reported
        session.biomeScanner.mockWeatherRainy = true
        
        // Puddle fishing unlocked: bypass geographic checks, cast Spinner Lure
        XCTAssertNoThrow(try session.castFishingLine(bait: .spinnerLures))
        session.fishingEngine.simulateTick()
        XCTAssertEqual(session.fishingEngine.currentState, .waiting)
        
        // Step 2: Sprite biting and hook set
        session.fishingEngine.triggerBite()
        session.fishingEngine.setHook()
        XCTAssertEqual(session.fishingEngine.currentState, .reeling)
        
        // Step 3: Complete breathing-sync reel and capture
        session.fishingEngine.updateBreathingTempo(simulatedRate: 6.0)
        session.fishingEngine.reelIn()
        
        XCTAssertEqual(session.fishingEngine.currentState, .captured)
        XCTAssertEqual(session.capturedPodmons.count, 1)
    }
    
    // MARK: - Gamification Evolution Tests
    
    class MockGameSessionDelegate: GameSessionDelegate {
        var evolvedPodmon: Podmon?
        var originalPodmon: Podmon?
        var didEvolveExpectation: XCTestExpectation?
        
        func gameSession(_ session: GameSession, didEvolvePodmon podmon: Podmon, from oldPodmon: Podmon) {
            evolvedPodmon = podmon
            originalPodmon = oldPodmon
            didEvolveExpectation?.fulfill()
        }
    }
    
    func testAutomaticEvolutionFlow() {
        let session = GameSession()
        let delegate = MockGameSessionDelegate()
        session.delegate = delegate
        
        // Setup Zephyr starter at level 9
        // Zephyr is Kinetic, to trigger kinetic evolution (Evolved Zephyr), kinetic weight must be >= 0.70.
        // We will initialize it at level 9, xp 99.0.
        let starter = Podmon(
            name: "Zephyr",
            faction: .kinetic,
            level: 9,
            xp: 99.0,
            kineticXP: 99.0,
            kineticXPWeight: 1.0
        )
        session.equippedPodmon = starter
        
        // Listen to notification
        let notificationExpectation = self.expectation(description: "Evolution notification post")
        let token = NotificationCenter.default.addObserver(forName: .podmonDidEvolve, object: session, queue: nil) { notification in
            XCTAssertNotNil(notification.userInfo?["podmon"] as? Podmon)
            XCTAssertNotNil(notification.userInfo?["oldPodmon"] as? Podmon)
            let evolved = notification.userInfo?["podmon"] as! Podmon
            XCTAssertEqual(evolved.name, "Evolved Zephyr")
            notificationExpectation.fulfill()
        }
        
        let delegateExpectation = self.expectation(description: "Evolution delegate trigger")
        delegate.didEvolveExpectation = delegateExpectation
        
        // Earn XP to cross level 10 -> will trigger level up to 10 and auto-evolution!
        // Kinetic drip postureGoodXP is 1.0 XP. We can just update head carriage (good posture)
        session.motionManager(session.motionManager, didUpdateHeadCarriage: 2.0)
        
        waitForExpectations(timeout: 2.0)
        NotificationCenter.default.removeObserver(token)
        
        XCTAssertEqual(session.equippedPodmon?.level, 10)
        XCTAssertEqual(session.equippedPodmon?.name, "Evolved Zephyr")
        XCTAssertEqual(delegate.originalPodmon?.name, "Zephyr")
        XCTAssertEqual(delegate.evolvedPodmon?.name, "Evolved Zephyr")
    }
    
    func testAutomaticTitanEvolutionFlow() {
        let session = GameSession()
        
        // Setup Zephyr starter at level 9, but with non-kinetic major weight (e.g. forge weight)
        // so it evolves into Titan Zephyr (kinetic weight < 0.70)
        let starter = Podmon(
            name: "Zephyr",
            faction: .kinetic,
            level: 9,
            xp: 99.0,
            kineticXP: 10.0,
            forgeXP: 90.0,
            kineticXPWeight: 0.1,
            forgeXPWeight: 0.9
        )
        session.equippedPodmon = starter
        
        // Earn XP to cross level 10
        session.motionManager(session.motionManager, didUpdateHeadCarriage: 2.0)
        
        XCTAssertEqual(session.equippedPodmon?.level, 10)
        XCTAssertEqual(session.equippedPodmon?.name, "Titan Zephyr")
    }
}
