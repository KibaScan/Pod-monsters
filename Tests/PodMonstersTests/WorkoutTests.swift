import XCTest
@testable import PodMonsters

@MainActor
final class WorkoutTests: XCTestCase {
    
    func testT1_F6_01_WorkoutStartStop() {
        let manager = WorkoutRepRestManager()
        XCTAssertEqual(manager.currentState, .idle)
        
        manager.startWorkout()
        XCTAssertEqual(manager.currentState, .activeSet)
        XCTAssertEqual(manager.currentRepCount, 0)
        XCTAssertEqual(manager.shieldDurability, 100.0)
    }
    
    func testT1_F6_02_RepCounting() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        manager.performRep(quality: 0.5)
        XCTAssertEqual(manager.currentRepCount, 1)
        
        // Wait 0.6s to bypass de-duplication
        let exp = expectation(description: "Wait between reps")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            manager.performRep(quality: 0.5)
            XCTAssertEqual(manager.currentRepCount, 2)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testT1_F6_03_ShieldDurabilityDrop() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Performing a 1.0 quality rep drops durability by 20%
        manager.performRep(quality: 1.0)
        XCTAssertEqual(manager.shieldDurability, 80.0)
    }
    
    func testT1_F6_04_ShieldCrackEvent() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        let expectation = self.expectation(description: "Shield crack event")
        manager.shieldCrackedCallback = {
            expectation.fulfill()
        }
        
        // Perform 5 high-quality reps (5 * 20.0 = 100.0 drop)
        // Wait 0.6s between each to pass de-duplication
        var currentRep = 0
        func doRep() {
            if currentRep < 5 {
                manager.performRep(quality: 1.0)
                currentRep += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    doRep()
                }
            }
        }
        
        doRep()
        
        waitForExpectations(timeout: 4.0)
        XCTAssertEqual(manager.shieldDurability, 0.0)
    }
    
    func testT1_F6_05_RestCaptureMode() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        XCTAssertEqual(manager.currentState, .activeSet)
        
        manager.startRestPeriod()
        XCTAssertEqual(manager.currentState, .restCapture)
    }
    
    func testT2_F6_01_RepCountBounds() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Zero and negative durations should be rejected
        manager.performRep(quality: 1.0, duration: 0.0)
        XCTAssertEqual(manager.currentRepCount, 0)
        
        manager.performRep(quality: 1.0, duration: -2.0)
        XCTAssertEqual(manager.currentRepCount, 0)
    }
    
    func testT2_F6_02_ExactShieldCrackBoundary() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Set durability exactly to 0.1
        manager.shieldDurability = 0.1
        
        var callbackFired = false
        manager.shieldCrackedCallback = {
            callbackFired = true
        }
        
        // Small quality rep that drops 1.0 durability (1.0 * 0.05 * 20 = 1.0)
        manager.performRep(quality: 0.05)
        
        XCTAssertEqual(manager.shieldDurability, 0.0)
        XCTAssertTrue(callbackFired)
    }
    
    func testT2_F6_03_SetDurationExceeded() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // 120 seconds duration cap
        manager.tickSetDuration(119.0)
        XCTAssertEqual(manager.currentState, .activeSet)
        
        manager.tickSetDuration(2.0) // exceeds 120.0
        XCTAssertEqual(manager.currentState, .restCapture)
    }
    
    func testT2_F6_04_RestDurationTimeout() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        manager.startRestPeriod()
        
        XCTAssertEqual(manager.currentState, .restCapture)
        
        manager.tickRestDuration(89.0)
        XCTAssertEqual(manager.currentState, .restCapture)
        
        manager.tickRestDuration(2.0) // exceeds 90.0
        XCTAssertEqual(manager.currentState, .idle)
    }
    
    func testT2_F6_05_SimultaneousRepEvents() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Fire concurrent reps immediately
        let exp = expectation(description: "Simultaneous reps fired")
        exp.expectedFulfillmentCount = 5
        
        for _ in 0..<5 {
            DispatchQueue.global().async {
                manager.performRep(quality: 1.0)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Only 1 rep should be counted due to our 0.5s de-duplication timestamp window
        XCTAssertEqual(manager.currentRepCount, 1)
    }
    
    func testDateInjectionDeduplication() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        let now = Date()
        
        // First rep
        manager.performRep(quality: 0.5, duration: 2.0, at: now)
        XCTAssertEqual(manager.currentRepCount, 1)
        
        // Rep inside de-duplication window (0.4s later) should be ignored
        manager.performRep(quality: 0.5, duration: 2.0, at: now.addingTimeInterval(0.4))
        XCTAssertEqual(manager.currentRepCount, 1)
        
        // Rep outside de-duplication window (0.5s later) should be accepted
        manager.performRep(quality: 0.5, duration: 2.0, at: now.addingTimeInterval(0.5))
        XCTAssertEqual(manager.currentRepCount, 2)
        
        // Rep exactly 0.5s later should be accepted
        manager.performRep(quality: 0.5, duration: 2.0, at: now.addingTimeInterval(1.0))
        XCTAssertEqual(manager.currentRepCount, 3)
    }
    
    func testHandsFreeRestTransitionUponShieldCrack() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        XCTAssertEqual(manager.currentState, .activeSet)
        
        var callbackFired = false
        manager.shieldCrackedCallback = {
            callbackFired = true
        }
        
        // Perform 5 high-quality reps (5 * 20 = 100) using custom Date injection to avoid de-duplication delays
        let now = Date()
        for i in 0..<5 {
            manager.performRep(quality: 1.0, duration: 2.0, at: now.addingTimeInterval(Double(i - 4) * 0.6))
        }
        
        XCTAssertEqual(manager.currentRepCount, 5)
        XCTAssertEqual(manager.shieldDurability, 0.0)
        XCTAssertTrue(callbackFired)
        
        // Verify hands-free auto transition to .restCapture
        XCTAssertEqual(manager.currentState, .restCapture)
        XCTAssertEqual(manager.restDuration, 0.0)
    }
    
    func testHealthKitWorkoutBridge() {
        let manager = WorkoutRepRestManager()
        let bridge = MockHealthKitWorkoutBridge(manager: manager)
        
        XCTAssertEqual(manager.currentState, .idle)
        
        // Simulate start
        bridge.simulateWorkoutStart()
        XCTAssertEqual(manager.currentState, .activeSet)
        
        // Simulate pause
        bridge.simulateWorkoutPause()
        XCTAssertEqual(manager.currentState, .restCapture)
        
        // Simulate end
        bridge.simulateWorkoutEnd()
        XCTAssertEqual(manager.currentState, .idle)
    }
    
    func testQualityClamping() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Quality > 1.0 should be clamped to 1.0 (drops durability by 20.0)
        manager.performRep(quality: 1.5, duration: 2.0, at: Date())
        XCTAssertEqual(manager.shieldDurability, 80.0)
        XCTAssertEqual(manager.currentRepCount, 1)
        
        // Quality < 0.0 should be clamped to 0.0 (drops durability by 0.0)
        let now = Date().addingTimeInterval(0.6)
        manager.performRep(quality: -0.5, duration: 2.0, at: now)
        XCTAssertEqual(manager.shieldDurability, 80.0)
        XCTAssertEqual(manager.currentRepCount, 2)
    }
    
    func testFutureRepsRejected() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Rep 1.1s in the future should be rejected
        let futureDate = Date().addingTimeInterval(1.1)
        manager.performRep(quality: 0.5, duration: 2.0, at: futureDate)
        XCTAssertEqual(manager.currentRepCount, 0)
        
        // Rep 0.9s in the future should be accepted
        let acceptableFutureDate = Date().addingTimeInterval(0.9)
        manager.performRep(quality: 0.5, duration: 2.0, at: acceptableFutureDate)
        XCTAssertEqual(manager.currentRepCount, 1)
    }
    
    func testOutOfOrderRepsRejected() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        let now = Date()
        manager.performRep(quality: 0.5, duration: 2.0, at: now)
        XCTAssertEqual(manager.currentRepCount, 1)
        
        // Rep with same timestamp (<= lastRepTime) should be rejected
        manager.performRep(quality: 0.5, duration: 2.0, at: now)
        XCTAssertEqual(manager.currentRepCount, 1)
        
        // Rep with earlier timestamp (< lastRepTime) should be rejected
        manager.performRep(quality: 0.5, duration: 2.0, at: now.addingTimeInterval(-1.0))
        XCTAssertEqual(manager.currentRepCount, 1)
    }
    
    func testBoundaryTimeouts() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // Verify set duration exact boundary timeout (>= 120.0)
        manager.tickSetDuration(120.0)
        XCTAssertEqual(manager.currentState, .restCapture)
        
        // Reset to activeSet
        manager.startWorkout()
        XCTAssertEqual(manager.currentState, .activeSet)
        manager.tickSetDuration(119.9)
        XCTAssertEqual(manager.currentState, .activeSet)
        manager.tickSetDuration(0.1)
        XCTAssertEqual(manager.currentState, .restCapture)
        
        // Verify rest duration exact boundary timeout (>= 90.0)
        manager.tickRestDuration(90.0)
        XCTAssertEqual(manager.currentState, .idle)
        
        manager.startRestPeriod()
        XCTAssertEqual(manager.currentState, .restCapture)
        manager.tickRestDuration(89.9)
        XCTAssertEqual(manager.currentState, .restCapture)
        manager.tickRestDuration(0.1)
        XCTAssertEqual(manager.currentState, .idle)
    }
    
    func testHealthKitBridgeResetsMetrics() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        manager.performRep(quality: 0.5, duration: 2.0, at: Date())
        manager.tickSetDuration(15.0)
        XCTAssertEqual(manager.currentRepCount, 1)
        XCTAssertEqual(manager.shieldDurability, 90.0)
        XCTAssertEqual(manager.setDuration, 15.0)
        
        // Bridging "running" should act like startWorkout and reset metrics
        manager.bridgeHealthKitState("running")
        XCTAssertEqual(manager.currentState, .activeSet)
        XCTAssertEqual(manager.currentRepCount, 0)
        XCTAssertEqual(manager.shieldDurability, 100.0)
        XCTAssertEqual(manager.setDuration, 0.0)
        XCTAssertEqual(manager.restDuration, 0.0)
    }
}
