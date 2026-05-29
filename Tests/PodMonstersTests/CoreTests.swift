import XCTest
@testable import PodMonsters

@MainActor
final class CoreTests: XCTestCase {
    
    // MARK: - F1: Podmon Model & Growth
    
    func testT1_F1_01_PodmonInitialization() {
        let zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        XCTAssertEqual(zephyr.name, "Zephyr")
        XCTAssertEqual(zephyr.faction, .kinetic)
        XCTAssertEqual(zephyr.level, 1)
        XCTAssertEqual(zephyr.xp, 0.0)
        XCTAssertEqual(zephyr.speed, 10.0)
        XCTAssertEqual(zephyr.agility, 10.0)
        
        let basalt = Podmon(name: "Basalt", faction: .forge)
        XCTAssertEqual(basalt.name, "Basalt")
        XCTAssertEqual(basalt.faction, .forge)
        XCTAssertEqual(basalt.level, 1)
        XCTAssertEqual(basalt.power, 10.0)
        XCTAssertEqual(basalt.hp, 100.0)
        
        let lumina = Podmon(name: "Lumina", faction: .aether)
        XCTAssertEqual(lumina.name, "Lumina")
        XCTAssertEqual(lumina.faction, .aether)
        XCTAssertEqual(lumina.level, 1)
        XCTAssertEqual(lumina.focus, 10.0)
        XCTAssertEqual(lumina.special, 10.0)
    }
    
    func testT1_F1_02_KineticXPGrowth() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        let initialSpeed = zephyr.speed
        let initialAgility = zephyr.agility
        
        zephyr.addXP(150.0, activityType: .kinetic)
        
        XCTAssertEqual(zephyr.xp, 50.0)
        XCTAssertGreaterThan(zephyr.speed, initialSpeed)
        XCTAssertGreaterThan(zephyr.agility, initialAgility)
    }
    
    func testT1_F1_03_ForgeXPGrowth() {
        var basalt = Podmon(name: "Basalt", faction: .forge)
        let initialPower = basalt.power
        let initialHP = basalt.hp
        
        basalt.addXP(150.0, activityType: .forge)
        
        XCTAssertEqual(basalt.xp, 50.0)
        XCTAssertGreaterThan(basalt.power, initialPower)
        XCTAssertGreaterThan(basalt.hp, initialHP)
    }
    
    func testT1_F1_04_AetherXPGrowth() {
        var lumina = Podmon(name: "Lumina", faction: .aether)
        let initialFocus = lumina.focus
        let initialSpecial = lumina.special
        
        lumina.addXP(150.0, activityType: .aether)
        
        XCTAssertEqual(lumina.xp, 50.0)
        XCTAssertGreaterThan(lumina.focus, initialFocus)
        XCTAssertGreaterThan(lumina.special, initialSpecial)
    }
    
    func testT1_F1_05_StandardEvolutionCheck() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        XCTAssertNil(zephyr.checkEvolution())
        
        // Add enough XP to level up beyond the evolution threshold (4500 XP)
        zephyr.addXP(4500.0, activityType: .kinetic)
        
        let evolved = zephyr.checkEvolution()
        XCTAssertNotNil(evolved)
        XCTAssertEqual(evolved?.name, "Evolved Zephyr")
        XCTAssertGreaterThan(evolved?.speed ?? 0, zephyr.speed)
    }
    
    func testT2_F1_01_LevelCapLimit() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic, level: 99)
        // Level 99 to 100 needs 9900 XP.
        // Add extreme XP.
        zephyr.addXP(1_000_000.0, activityType: .kinetic)
        
        XCTAssertEqual(zephyr.level, 100)
        XCTAssertEqual(zephyr.xp, 0.0)
        
        // Try adding more XP at cap
        zephyr.addXP(100.0, activityType: .kinetic)
        XCTAssertEqual(zephyr.level, 100)
        XCTAssertEqual(zephyr.xp, 0.0)
    }
    
    func testT2_F1_02_NonMatchingFactionXP() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        let initialSpeed = zephyr.speed
        
        // Non-matching XP (Forge on Kinetic) should have degraded rate (50%)
        zephyr.addXP(100.0, activityType: .forge)
        
        XCTAssertEqual(zephyr.xp, 50.0)
        XCTAssertEqual(zephyr.speed, initialSpeed)
        
        // Match XP (Kinetic on Kinetic)
        var zephyr2 = Podmon(name: "Zephyr2", faction: .kinetic)
        zephyr2.addXP(100.0, activityType: .kinetic)
        
        XCTAssertEqual(zephyr2.xp, 0.0)
        XCTAssertEqual(zephyr2.level, 2)
        XCTAssertGreaterThan(zephyr2.speed, zephyr.speed)
    }
    
    func testT2_F1_03_EvolutionXPBoundaries() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        
        // Exactly 1 XP below threshold (899.0)
        zephyr.addXP(899.0, activityType: .kinetic)
        XCTAssertNil(zephyr.checkEvolution())
        
        // Exactly at threshold (900.0 total)
        zephyr.addXP(1.0, activityType: .kinetic)
        XCTAssertNotNil(zephyr.checkEvolution())
    }
    
    func testT2_F1_04_LevelUpStatCalculation() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        let baseSpeed = zephyr.speed
        
        // Level up by hitting 100 XP
        zephyr.addXP(100.0, activityType: .kinetic)
        
        XCTAssertEqual(zephyr.level, 2)
        XCTAssertGreaterThan(zephyr.speed, baseSpeed * 1.1)
    }
    
    func testT2_F1_05_XPFloatOverflow() {
        var zephyr = Podmon(name: "Zephyr", faction: .kinetic)
        
        // Send extremely large Double value
        zephyr.addXP(Double.greatestFiniteMagnitude, activityType: .kinetic)
        
        // Should cap safely or handle without crash
        XCTAssertEqual(zephyr.level, 100)
        XCTAssertEqual(zephyr.xp, 0.0)
    }
    
    // MARK: - F2: Bait Economy & Budgets
    
    func testT1_F2_01_BaitTypeSelection() {
        XCTAssertEqual(BaitType.ironHooks.associatedFaction(), .forge)
        XCTAssertEqual(BaitType.spinnerLures.associatedFaction(), .kinetic)
        XCTAssertEqual(BaitType.mindBeads.associatedFaction(), .aether)
        XCTAssertNil(BaitType.masterLures.associatedFaction())
    }
    
    func testT1_F2_02_BaitUsageMechanics() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 3
        
        try? session.useBait(.ironHooks)
        XCTAssertEqual(session.baitInventory[.ironHooks], 2)
    }
    
    func testT1_F2_03_EmptyBaitRejection() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 0
        
        XCTAssertThrowsError(try session.useBait(.ironHooks)) { error in
            XCTAssertEqual(error as? BaitError, .emptyBait)
        }
    }
    
    func testT1_F2_04_BaitAcquisition() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 5
        
        try? session.addBait(.ironHooks, count: 2)
        XCTAssertEqual(session.baitInventory[.ironHooks], 7)
    }
    
    func testT1_F2_05_SubscriptionMasterLures() {
        let session = GameSession()
        session.isSubscriber = false
        session.baitInventory[.masterLures] = 1
        
        // Non-subscriber cannot use Master Lures
        XCTAssertThrowsError(try session.useBait(.masterLures)) { error in
            XCTAssertEqual(error as? BaitError, .subscriptionRequired)
        }
        
        // Subscriber can use Master Lures
        session.isSubscriber = true
        XCTAssertNoThrow(try session.useBait(.masterLures))
        XCTAssertEqual(session.baitInventory[.masterLures], 0)
    }
    
    func testT2_F2_01_BaitInventoryCap() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 95
        
        // Exceed cap of 99
        XCTAssertThrowsError(try session.addBait(.ironHooks, count: 10)) { error in
            XCTAssertEqual(error as? BaitError, .inventoryCapExceeded)
        }
        XCTAssertEqual(session.baitInventory[.ironHooks], 99)
    }
    
    func testT2_F2_02_ZeroCountDecrement() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 0
        
        XCTAssertThrowsError(try session.useBait(.ironHooks))
        XCTAssertEqual(session.baitInventory[.ironHooks], 0)
    }
    
    func testT2_F2_03_ThreadSafeSimultaneousConsumptions() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 50
        
        let expectation = self.expectation(description: "Concurrent consumptions")
        expectation.expectedFulfillmentCount = 20
        
        for _ in 0..<20 {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    do {
                        try session.useBait(.ironHooks)
                    } catch {}
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(session.baitInventory[.ironHooks], 30)
    }
    
    func testT2_F2_04_ConcurrentBaitEarnings() {
        let session = GameSession()
        session.baitInventory[.ironHooks] = 10
        
        let expectation = self.expectation(description: "Concurrent earnings")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    try? session.addBait(.ironHooks, count: 2)
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(session.baitInventory[.ironHooks], 30)
    }
    
    func testT2_F2_05_InvalidBaitTypeHandling() {
        let session = GameSession()
        
        // Pass invalid count/parameters or check throwing for unsupported
        let invalidBait = BaitType(rawValue: "goldenLure")
        XCTAssertNil(invalidBait)
    }
}
