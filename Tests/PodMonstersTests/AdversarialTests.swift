import XCTest
import CoreLocation
import CoreMotion
@testable import PodMonsters

@MainActor
final class AdversarialTests: XCTestCase {
    
    // MARK: - Podmon XP & Growth (NaN/Infinity/Negative)
    
    func testAdversarial_PodmonXP_NaN() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        
        // 1. Add NaN XP
        zephyr.addXP(Double.nan, activityType: .kinetic)
        
        // XP becomes NaN
        XCTAssertTrue(zephyr.xp.isNaN)
        
        // 2. Further normal XP additions also remain NaN, bricking progress
        zephyr.addXP(50.0, activityType: .kinetic)
        XCTAssertTrue(zephyr.xp.isNaN)
        XCTAssertEqual(zephyr.level, 1) // Level is stuck at 1
    }
    
    func testAdversarial_PodmonXP_Infinity() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        
        // 1. Add Infinity XP
        zephyr.addXP(Double.infinity, activityType: .kinetic)
        
        // Level reaches max cap
        XCTAssertEqual(zephyr.level, 100)
        XCTAssertEqual(zephyr.xp, 0.0)
        
        // Stats become NaN because kineticXPWeight became NaN (infinity / infinity)
        XCTAssertTrue(zephyr.speed.isNaN)
        XCTAssertTrue(zephyr.agility.isNaN)
    }
    
    func testAdversarial_PodmonXP_Negative() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        let initialSpeed = zephyr.speed
        
        // 1. Add negative XP
        zephyr.addXP(-50.0, activityType: .kinetic)
        
        // XP decreases to negative value
        XCTAssertEqual(zephyr.xp, -50.0)
        XCTAssertEqual(zephyr.level, 1)
        XCTAssertEqual(zephyr.speed, initialSpeed)
    }
    
    // MARK: - Bait Economy & Budgets (Negative/Overflow)
    
    func testAdversarial_BaitInventory_Negative() {
        let session = GameSession()
        
        // Try adding a negative count of bait
        // Since count has no positive check, this subtracts from the default 5
        try? session.addBait(.ironHooks, count: -10)
        
        // Inventory count becomes negative
        XCTAssertEqual(session.baitInventory[.ironHooks], -5)
    }
    
    // MARK: - AirPodsMotionManager (NaN/Infinity)
    
    func testAdversarial_MotionManager_NaN_Infinity() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // 1. Simulate head movement with NaN and Infinity
        manager.simulateHeadMovement(yaw: Double.nan, pitch: Double.infinity)
        
        // Calibration angles wrap to 0.0 gracefully
        XCTAssertEqual(manager.calibrationDelta.yaw, 0.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 0.0)
        
        // 2. Feed micro-movements with NaN and Infinity
        manager.feedMicroMovements(magnitude: Double.nan)
        XCTAssertEqual(manager.stillnessScore, 1.0)
        
        manager.feedMicroMovements(magnitude: Double.infinity)
        XCTAssertEqual(manager.stillnessScore, 1.0)
    }
    
    // MARK: - FishingEngine (NaN Propagation)
    
    func testAdversarial_FishingEngine_NaNStillness() {
        let engine = FishingEngine()
        engine.castLine(bait: .spinnerLures)
        engine.simulateTick()
        engine.triggerBite()
        engine.setHook()
        
        // 1. Update parasympathetic data with NaN stillness score
        engine.updateParasympatheticData(hrv: 60.0, stillness: Double.nan)
        XCTAssertFalse(engine.parasympatheticShiftConfirmed)
        XCTAssertTrue(engine.stillnessScore.isNaN)
        
        // 2. Set breathing tempo to perfect match
        // Breathing tempo triggers lineTension update using stillnessFactor, which is NaN.
        // Thus, lineTension propagates NaN.
        engine.updateBreathingTempo(simulatedRate: 6.0)
        XCTAssertTrue(engine.lineTension.isNaN)
    }
    
    // MARK: - WorkoutRepRestManager (NaN Quality & Durability)
    
    func testAdversarial_WorkoutManager_NaNQuality() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // 1. Perform a rep with NaN quality
        // Quality clamping min/max with NaN evaluates to NaN, propagating to durability.
        manager.performRep(quality: Double.nan)
        
        XCTAssertTrue(manager.shieldDurability.isNaN)
        
        // 2. Further reps do not trigger rest period transitions because NaN <= 0.0 is false
        manager.performRep(quality: 1.0)
        XCTAssertEqual(manager.currentState, .activeSet)
        XCTAssertTrue(manager.shieldDurability.isNaN)
    }
    
    func testAdversarial_WorkoutManager_NegativeAndNaNDurationTicks() {
        let manager = WorkoutRepRestManager()
        manager.startWorkout()
        
        // 1. Tick negative set duration
        manager.tickSetDuration(-50.0)
        XCTAssertEqual(manager.setDuration, -50.0)
        
        // 2. Tick NaN duration
        manager.tickSetDuration(Double.nan)
        XCTAssertTrue(manager.setDuration.isNaN)
        
        // 3. Negative rest duration ticks
        manager.startRestPeriod()
        manager.tickRestDuration(-10.0)
        XCTAssertEqual(manager.restDuration, -10.0)
    }
    
    // MARK: - BiomeScanner (Geographic Boundaries & NaN Coordinates)
    
    func testAdversarial_BiomeScanner_ExtremeCoordinates() async {
        struct MockNetworkProvider: BiomeNetworkProvider {
            func fetchOverpassData(latitude: Double, longitude: Double) async throws -> String {
                return "{}"
            }
        }
        struct MockWeatherProvider: WeatherProvider {
            func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> (isRainy: Bool, temperature: Double) {
                return (false, 22.0)
            }
        }
        
        let scanner = BiomeScanner(networkProvider: MockNetworkProvider(), weatherProvider: MockWeatherProvider())
        
        // 1. Scan with coordinates outside geographic ranges
        let extremeCoord = CLLocationCoordinate2D(latitude: 95.0, longitude: 190.0)
        scanner.mockTime = makeUTCDate(year: 2026, month: 3, day: 20, hour: 12, minute: 0)
        
        let state = try? await scanner.scanCurrentLocation(coordinate: extremeCoord)
        XCTAssertNotNil(state)
        XCTAssertEqual(state?.solarPeriod, .dusk) // Clamped to latitude 90, longitude 180, which is dusk at 12:00 UTC on equinox
        
        // 2. Scan with NaN coordinate
        let nanCoord = CLLocationCoordinate2D(latitude: Double.nan, longitude: Double.nan)
        let nanState = try? await scanner.scanCurrentLocation(coordinate: nanCoord)
        XCTAssertEqual(nanState?.type, .neutral)
        XCTAssertEqual(nanState?.temperature, 0.0)
    }
    
    // Helper to make UTC date
    private func makeUTCDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return utcCalendar.date(from: components)!
    }
}
