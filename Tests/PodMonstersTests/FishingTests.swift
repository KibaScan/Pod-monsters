import XCTest
@testable import PodMonsters

@MainActor
final class FishingTests: XCTestCase {
    
    func testT1_F5_01_FishingStateCasting() {
        let engine = FishingEngine()
        XCTAssertEqual(engine.currentState, .idle)
        
        engine.castLine(bait: .spinnerLures)
        XCTAssertEqual(engine.currentState, .casting)
        XCTAssertEqual(engine.currentBait, .spinnerLures)
        
        engine.simulateTick()
        XCTAssertEqual(engine.currentState, .waiting)
    }
    
    func testT1_F5_02_BiteTrigger() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        
        let expectation = self.expectation(description: "Haptic tug callback")
        engine.hapticTugCallback = {
            expectation.fulfill()
        }
        
        engine.triggerBite()
        XCTAssertEqual(engine.currentState, .biting)
        waitForExpectations(timeout: 1.0)
    }
    
    func testT1_F5_03_ReelInTension() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        XCTAssertEqual(engine.currentState, .reeling)
        XCTAssertEqual(engine.lineTension, 0.3)
        
        // Erratic breathing: score will be low (0.0), tension increases
        engine.updateBreathingTempo(simulatedRate: 20.0)
        XCTAssertEqual(engine.breathPaceMatchScore, 0.0)
        XCTAssertEqual(engine.lineTension, 0.55) // 0.3 + 0.25
        
        // Match breathing perfectly: score is 1.0, tension decreases
        engine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertEqual(engine.breathPaceMatchScore, 1.0)
        XCTAssertEqual(engine.lineTension, 0.40) // 0.55 - 0.15
    }
    
    func testT1_F5_04_CaptureSuccess() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        let expectation = self.expectation(description: "Capture success callback")
        engine.captureSuccessCallback = { podmon in
            XCTAssertEqual(podmon.faction, .kinetic)
            expectation.fulfill()
        }
        
        // Set breath match score to maximum
        engine.updateBreathingTempo(simulatedRate: 6.0)
        // Tension is 0.3 - 0.15 = 0.15 (which is < 0.3 threshold)
        
        // Call reelIn to trigger capture check
        engine.reelIn()
        
        XCTAssertEqual(engine.currentState, .captured)
        waitForExpectations(timeout: 1.0)
    }
    
    func testT1_F5_05_LineSnapEvent() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        // Reeling repeatedly increases tension
        engine.reelIn() // 0.3 + 0.15 = 0.45
        engine.reelIn() // 0.60
        engine.reelIn() // 0.75
        engine.reelIn() // 0.90
        engine.reelIn() // 1.05 -> snaps!
        
        XCTAssertEqual(engine.currentState, .snapped)
        XCTAssertEqual(engine.lineTension, 1.0)
    }
    
    func testT2_F5_01_BreathPacePerfectMatch() {
        let engine = FishingEngine()
        
        // Perfect 6.0 breaths/min pace -> score 1.0
        engine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertEqual(engine.breathPaceMatchScore, 1.0)
    }
    
    func testT2_F5_02_ExtremeBreathAsynchrony() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        // Massive asynchrony
        engine.updateBreathingTempo(simulatedRate: 50.0)
        XCTAssertEqual(engine.breathPaceMatchScore, 0.0)
        XCTAssertEqual(engine.lineTension, 0.55) // 0.3 + 0.25
        
        // Zero breathing
        engine.updateBreathingTempo(simulatedRate: 0.0)
        XCTAssertEqual(engine.breathPaceMatchScore, 0.0)
        XCTAssertEqual(engine.lineTension, 0.8) // 0.55 + 0.25
    }
    
    func testT2_F5_03_TensionSnapBoundary() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        // Set tension exactly at 0.999
        engine.lineTension = 0.999
        engine.updateBreathingTempo(simulatedRate: 6.0) // doesn't exceed 1.0, decreases tension
        XCTAssertEqual(engine.currentState, .reeling)
        
        // Force to exactly 1.0 -> snapped
        engine.lineTension = 1.0
        engine.reelIn()
        XCTAssertEqual(engine.currentState, .snapped)
    }
    
    func testT2_F5_04_WaitingTimeouts() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        XCTAssertEqual(engine.currentState, .waiting)
        
        // Simulate waiting past timeout limit
        engine.simulateTimeout()
        XCTAssertEqual(engine.currentState, .idle)
        XCTAssertNil(engine.currentBait)
    }
    
    func testT2_F5_05_RapidReelToggle() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        // Fast reel commands
        for _ in 0..<10 {
            engine.reelIn()
        }
        
        XCTAssertEqual(engine.currentState, .snapped)
        XCTAssertEqual(engine.lineTension, 1.0)
    }
    
    func testBlueMind_PatienceInitializationAndDecay() {
        let engine = FishingEngine()
        XCTAssertEqual(engine.patienceLevel, 1.0)
        XCTAssertEqual(engine.hrvScore, 60.0)
        XCTAssertEqual(engine.stillnessScore, 1.0)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        XCTAssertEqual(engine.currentState, .waiting)
        XCTAssertEqual(engine.patienceLevel, 1.0)
        
        // 1. Test normal decay when parasympathetic shift is NOT confirmed
        engine.simulateTick()
        XCTAssertEqual(engine.patienceLevel, 0.95, accuracy: 0.0001)
        
        // 2. Confirmed shift (stillness > 0.95) -> patience level resets/extends
        engine.updateParasympatheticData(hrv: 75.0, stillness: 0.98)
        XCTAssertTrue(engine.parasympatheticShiftConfirmed)
        XCTAssertEqual(engine.patienceLevel, 1.0)
        XCTAssertEqual(engine.hrvScore, 75.0)
        XCTAssertEqual(engine.stillnessScore, 0.98)
        
        // 3. Test decay when parasympathetic shift IS confirmed (decay is 0.0)
        engine.simulateTick()
        XCTAssertEqual(engine.patienceLevel, 1.0)
        
        // 4. Lose parasympathetic shift (stillness <= 0.95)
        engine.updateParasympatheticData(hrv: 70.0, stillness: 0.90)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        XCTAssertEqual(engine.stillnessScore, 0.90)
        
        // Decay works again
        engine.simulateTick()
        XCTAssertEqual(engine.patienceLevel, 0.95, accuracy: 0.0001)
    }
    
    func testBlueMind_PatienceTimeout() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        
        // Decay until 0.0
        for _ in 0..<20 {
            engine.simulateTick()
        }
        
        XCTAssertEqual(engine.patienceLevel, 0.0)
        XCTAssertEqual(engine.currentState, .idle)
        XCTAssertNil(engine.currentBait)
    }
    
    func testBlueMind_TaiChiReelBreathingTension() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        XCTAssertEqual(engine.currentState, .reeling)
        XCTAssertEqual(engine.lineTension, 0.3)
        
        // 1. High stillness score (e.g. 0.98) -> stillnessFactor = 1.0
        engine.updateParasympatheticData(hrv: 80.0, stillness: 0.98)
        XCTAssertTrue(engine.parasympatheticShiftConfirmed)
        
        // Perfect match (score > 0.8) -> tension decreases by 0.15 * stillnessFactor = 0.15
        engine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertEqual(engine.lineTension, 0.15, accuracy: 0.0001)
        
        // 2. Lower stillness score (e.g. 0.5) -> stillnessFactor = 0.5
        engine.updateParasympatheticData(hrv: 80.0, stillness: 0.50)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        
        // Perfect match -> tension decreases by 0.15 * stillnessFactor = 0.075
        engine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertEqual(engine.lineTension, 0.075, accuracy: 0.0001)
        
        // 3. Erratic breathing (score < 0.3) -> tension increases by 0.25 * (2.0 - stillnessScore)
        // With stillness = 0.50, increase = 0.25 * 1.5 = 0.375
        engine.updateBreathingTempo(simulatedRate: 20.0)
        XCTAssertEqual(engine.lineTension, 0.45, accuracy: 0.0001)
    }
    
    func testBlueMind_LineSnapObserver() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        // Directly set lineTension >= 1.0
        engine.lineTension = 1.2
        XCTAssertEqual(engine.currentState, .snapped)
        XCTAssertEqual(engine.lineTension, 1.0)
    }
    
    func testBlueMind_GameSessionStillnessIntegration() {
        let session = GameSession()
        XCTAssertEqual(session.fishingEngine.stillnessScore, 1.0)
        
        // Simulate stillness score update from AirPodsMotionManager
        let manager = session.motionManager
        session.motionManager(manager, didUpdateStillnessScore: 0.98)
        
        XCTAssertEqual(session.fishingEngine.stillnessScore, 0.98)
        XCTAssertTrue(session.fishingEngine.parasympatheticShiftConfirmed)
        XCTAssertEqual(session.fishingEngine.patienceLevel, 1.0)
    }
    
    func testT1_F6_06_BiomeBaitCatchTable() {
        let testCases: [(BiomeType, BaitType, String, Faction)] = [
            // Water
            (.water, .mindBeads, "Aqua Spirit", .aether),
            (.water, .spinnerLures, "River Dart", .kinetic),
            (.water, .ironHooks, "Rust Barnacle", .forge),
            (.water, .masterLures, "River Dart", .kinetic),
            
            // Green Space
            (.greenSpace, .spinnerLures, "Leaf Sprite", .kinetic),
            (.greenSpace, .masterLures, "Leaf Sprite", .kinetic),
            (.greenSpace, .mindBeads, "Grove Pixie", .aether),
            (.greenSpace, .ironHooks, "Iron Sprout", .forge),
            
            // Urban
            (.urban, .ironHooks, "Street Racer", .forge),
            (.urban, .spinnerLures, "Neon Swallow", .kinetic),
            (.urban, .mindBeads, "Cyber Sprite", .aether),
            
            // Gym
            (.gym, .ironHooks, "Concrete Golem", .forge),
            (.gym, .spinnerLures, "Aero Boulder", .kinetic),
            (.gym, .mindBeads, "Zen Pebble", .aether),
            
            // Neutral/Default fallbacks
            (.neutral, .spinnerLures, "Wild Puddle Sprite", .kinetic),
            (.quietIndoor, .ironHooks, "Wild Puddle Sprite", .kinetic)
        ]
        
        for (biome, bait, expectedName, expectedFaction) in testCases {
            let engine = FishingEngine()
            engine.castLine(bait: bait)
            engine.simulateTick()
            engine.triggerBite()
            engine.setHook()
            
            let expectation = self.expectation(description: "Capture in \(biome) with \(bait)")
            engine.captureSuccessCallback = { podmon in
                XCTAssertEqual(podmon.name, expectedName, "Failed on \(biome) + \(bait)")
                XCTAssertEqual(podmon.faction, expectedFaction, "Failed on \(biome) + \(bait)")
                expectation.fulfill()
            }
            
            // Set breath match score to maximum
            engine.updateBreathingTempo(simulatedRate: 6.0)
            
            // Call reelIn with explicit biome parameter
            engine.reelIn(biome: biome)
            
            XCTAssertEqual(engine.currentState, .captured)
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func testT1_F6_07_BiomeBaitCatchTableUsingCurrentBiome() {
        let engine = FishingEngine()
        engine.currentBiome = .gym
        engine.castLine(bait: .ironHooks)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        let expectation = self.expectation(description: "Capture with currentBiome")
        engine.captureSuccessCallback = { podmon in
            XCTAssertEqual(podmon.name, "Concrete Golem")
            XCTAssertEqual(podmon.faction, .forge)
            expectation.fulfill()
        }
        
        engine.updateBreathingTempo(simulatedRate: 6.0)
        
        // reelIn() without parameters should resolve to currentBiome (.gym)
        engine.reelIn()
        
        XCTAssertEqual(engine.currentState, .captured)
        waitForExpectations(timeout: 1.0)
    }
    
    func testT1_F6_08_GameSessionBiomeScannerSync() {
        let session = GameSession()
        
        // Mock scanner state to .water
        session.biomeScanner.currentState = BiomeState(type: .water, solarPeriod: .day, isTempestActive: false, temperature: 22.0)
        
        // Trigger didUpdateStillnessScore
        session.motionManager(session.motionManager, didUpdateStillnessScore: 0.98)
        
        // Verify currentBiome was synchronized
        XCTAssertEqual(session.fishingEngine.currentBiome, .water)
    }
}
