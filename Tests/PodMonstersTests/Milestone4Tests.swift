import XCTest
@testable import PodMonsters

@MainActor
final class Milestone4Tests: XCTestCase {
    
    // MARK: - Release Buddy Feature Tests
    
    func testReleaseBuddy_Success() {
        let session = GameSession()
        session.equippedBuddy = Monster(name: "Zephyr", faction: .kinetic)
        
        let wild = Monster(name: "Wild Basalt", faction: .forge)
        session.capturedMonsters.append(wild)
        
        XCTAssertEqual(session.capturedMonsters.count, 1)
        XCTAssertEqual(session.equippedBuddy?.xp, 0.0)
        XCTAssertEqual(session.equippedBuddy?.level, 1)
        
        XCTAssertNoThrow(try session.releaseBuddy(wild))
        
        // Assert: Monster is removed from capturedMonsters
        XCTAssertTrue(session.capturedMonsters.isEmpty)
        
        // Assert: 500 XP added to equippedBuddy (level goes from 1 to 6)
        XCTAssertEqual(session.equippedBuddy?.level, 6)
    }
    
    func testReleaseBuddy_MonsterNotFound() {
        let session = GameSession()
        session.equippedBuddy = Monster(name: "Zephyr", faction: .kinetic)
        
        let wild = Monster(name: "Wild Basalt", faction: .forge)
        // Note: wild is NOT added to capturedMonsters
        
        XCTAssertThrowsError(try session.releaseBuddy(wild)) { error in
            XCTAssertEqual(error as? SessionError, .monsterNotFound)
        }
    }
    
    // MARK: - HRV Patience Gating Tests
    
    func testSessionBaselineHRV_EstablishedOnCast() {
        let engine = FishingEngine()
        engine.hrvScore = 72.5
        
        XCTAssertEqual(engine.currentState, .idle)
        engine.castLine(bait: .spinnerLures)
        
        XCTAssertEqual(engine.currentState, .casting)
        XCTAssertEqual(engine.sessionBaselineHRV, 72.5)
    }
    
    // MARK: - Parasympathetic Shift Gating Tests
    
    func testParasympatheticShift_GatedByStillnessAndHRV() {
        let engine = FishingEngine()
        engine.hrvScore = 60.0
        engine.castLine(bait: .spinnerLures) // sessionBaselineHRV = 60.0
        
        // Target baseline HRV threshold: 60.0 - 5.0 = 55.0
        
        // Test Case A: High stillness (> 0.95) but low HRV (< 55.0) -> No Shift
        engine.updateParasympatheticData(hrv: 54.0, stillness: 0.98)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        
        // Test Case B: Low stillness (<= 0.95) but high HRV (>= 55.0) -> No Shift
        engine.updateParasympatheticData(hrv: 70.0, stillness: 0.90)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        
        // Test Case C: High stillness (> 0.95) and high HRV (>= 55.0) -> Shift Confirmed
        engine.updateParasympatheticData(hrv: 56.0, stillness: 0.98)
        XCTAssertTrue(engine.parasympatheticShiftConfirmed)
    }
    
    // MARK: - Stillness Patience Reset Tests
    
    func testPatienceLevel_ResetOnlyOnTransitionFromFalseToTrue() {
        let engine = FishingEngine()
        engine.hrvScore = 60.0
        engine.castLine(bait: .spinnerLures) // sessionBaselineHRV = 60.0
        engine.simulateTick() // transitions to .waiting state
        
        XCTAssertEqual(engine.currentState, .waiting)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        
        // Lower patience manually to 0.5
        engine.patienceLevel = 0.5
        
        // 1. First shift confirmation: false -> true. Patience level MUST reset to 1.0.
        engine.updateParasympatheticData(hrv: 60.0, stillness: 0.98)
        XCTAssertTrue(engine.parasympatheticShiftConfirmed)
        XCTAssertEqual(engine.patienceLevel, 1.0)
        
        // Lower patience manually back to 0.5 while parasympatheticShiftConfirmed is still true
        engine.patienceLevel = 0.5
        
        // 2. Second shift update: still true. Patience level MUST NOT reset.
        engine.updateParasympatheticData(hrv: 62.0, stillness: 0.99)
        XCTAssertTrue(engine.parasympatheticShiftConfirmed)
        XCTAssertEqual(engine.patienceLevel, 0.5)
    }
    
    // MARK: - Transient Casting State Tests
    
    func testTransientCastingState() {
        let engine = FishingEngine()
        XCTAssertEqual(engine.currentState, .idle)
        
        engine.castLine(bait: .spinnerLures)
        
        // Assert state is .casting (transient) and patience is initialized
        XCTAssertEqual(engine.currentState, .casting)
        XCTAssertEqual(engine.patienceLevel, 1.0)
        
        // Call simulateTick to transition
        engine.simulateTick()
        
        // Assert state transitioned to .waiting and no patience decay occurred on this transient tick
        XCTAssertEqual(engine.currentState, .waiting)
        XCTAssertEqual(engine.patienceLevel, 1.0)
    }
}
