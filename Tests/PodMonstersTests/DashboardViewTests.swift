import XCTest
import SwiftUI
@testable import PodMonsters

@MainActor
final class DashboardViewTests: XCTestCase {
    
    func testDashboardViewInstantiation() {
        let session = GameSession()
        let view = DashboardView(session: session)
        XCTAssertNotNil(view)
        XCTAssertNotNil(session.motionManager)
        XCTAssertNotNil(session.biomeScanner)
        XCTAssertNotNil(session.fishingEngine)
        XCTAssertNotNil(session.workoutManager)
    }
    
    func testSniffModeViewBinding() {
        let session = GameSession()
        let view = SniffModeView(motionManager: session.motionManager)
        XCTAssertEqual(view.motionManager.isTracking, false)
        XCTAssertEqual(view.motionManager.isConnected, true)
    }
    
    func testBiomeViewBinding() {
        let session = GameSession()
        let view = BiomeView(biomeScanner: session.biomeScanner, gameSession: session)
        XCTAssertEqual(view.biomeScanner.isScanning, false)
        XCTAssertNil(view.biomeScanner.currentState)
    }
    
    func testFishingViewBinding() {
        let session = GameSession()
        let view = FishingView(fishingEngine: session.fishingEngine, gameSession: session)
        XCTAssertEqual(view.fishingEngine.currentState, .idle)
        XCTAssertEqual(view.fishingEngine.lineTension, 0.0)
    }
    
    func testWorkoutViewBinding() {
        let session = GameSession()
        let view = WorkoutView(workoutManager: session.workoutManager, gameSession: session)
        XCTAssertEqual(view.workoutManager.currentState, .idle)
        XCTAssertEqual(view.workoutManager.currentRepCount, 0)
    }
}
