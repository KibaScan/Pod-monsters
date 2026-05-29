import XCTest
@testable import PodMonsters

@MainActor
final class PodmonTests: XCTestCase {
    
    // MARK: - Evolution Tests
    
    func testPureZephyrEvolution() {
        var zephyr = Podmon.zephyr()
        XCTAssertEqual(zephyr.name, "Zephyr")
        XCTAssertEqual(zephyr.level, 1)
        XCTAssertNil(zephyr.checkEvolution())
        
        // Add matching Kinetic XP (900.0) to reach level 10
        zephyr.addXP(900.0, activityType: .kinetic)
        XCTAssertEqual(zephyr.level, 10)
        XCTAssertGreaterThanOrEqual(zephyr.kineticXPWeight, 0.70)
        
        guard let evolved = zephyr.checkEvolution() else {
            XCTFail("Zephyr should be able to evolve at level 10")
            return
        }
        
        XCTAssertEqual(evolved.name, "Evolved Zephyr")
        XCTAssertEqual(evolved.level, 10)
        XCTAssertEqual(evolved.speed, zephyr.speed + 20.0)
        XCTAssertEqual(evolved.hp, zephyr.hp + 20.0)
    }
    
    func testHybridZephyrEvolution() {
        var zephyr = Podmon.zephyr()
        XCTAssertEqual(zephyr.name, "Zephyr")
        XCTAssertNil(zephyr.checkEvolution())
        
        // Add kinetic XP and forge XP to fall below 0.70 weight
        // Matching kinetic XP: 400.0
        zephyr.addXP(400.0, activityType: .kinetic)
        
        // Non-matching forge XP: 1000.0 (degraded to 500.0 forge XP)
        zephyr.addXP(1000.0, activityType: .forge)
        
        XCTAssertEqual(zephyr.level, 10)
        XCTAssertLessThan(zephyr.kineticXPWeight, 0.70)
        
        guard let evolved = zephyr.checkEvolution() else {
            XCTFail("Zephyr should be able to evolve at level 10")
            return
        }
        
        XCTAssertEqual(evolved.name, "Titan Zephyr")
        XCTAssertEqual(evolved.level, 10)
        XCTAssertEqual(evolved.speed, zephyr.speed + 20.0)
        XCTAssertEqual(evolved.hp, zephyr.hp + 20.0)
    }
    
    func testPureBasaltEvolution() {
        var basalt = Podmon.basalt()
        XCTAssertEqual(basalt.name, "Basalt")
        XCTAssertNil(basalt.checkEvolution())
        
        // Add matching Forge XP (900.0) to reach level 10
        basalt.addXP(900.0, activityType: .forge)
        XCTAssertEqual(basalt.level, 10)
        XCTAssertGreaterThanOrEqual(basalt.forgeXPWeight, 0.70)
        
        guard let evolved = basalt.checkEvolution() else {
            XCTFail("Basalt should be able to evolve at level 10")
            return
        }
        
        XCTAssertEqual(evolved.name, "Evolved Basalt")
        XCTAssertEqual(evolved.level, 10)
        XCTAssertEqual(evolved.power, basalt.power + 20.0)
        XCTAssertEqual(evolved.hp, basalt.hp + 20.0)
    }
    
    func testHybridBasaltEvolution() {
        var basalt = Podmon.basalt()
        XCTAssertEqual(basalt.name, "Basalt")
        XCTAssertNil(basalt.checkEvolution())
        
        // Add forge XP and aether XP to fall below 0.70 weight
        // Matching forge XP: 400.0
        basalt.addXP(400.0, activityType: .forge)
        
        // Non-matching aether XP: 1000.0 (degraded to 500.0 aether XP)
        basalt.addXP(1000.0, activityType: .aether)
        
        XCTAssertEqual(basalt.level, 10)
        XCTAssertLessThan(basalt.forgeXPWeight, 0.70)
        
        guard let evolved = basalt.checkEvolution() else {
            XCTFail("Basalt should be able to evolve at level 10")
            return
        }
        
        XCTAssertEqual(evolved.name, "Monk Basalt")
        XCTAssertEqual(evolved.level, 10)
        XCTAssertEqual(evolved.power, basalt.power + 20.0)
        XCTAssertEqual(evolved.hp, basalt.hp + 20.0)
    }
    
    func testPureLuminaEvolution() {
        var lumina = Podmon.lumina()
        XCTAssertEqual(lumina.name, "Lumina")
        XCTAssertNil(lumina.checkEvolution())
        
        // Add matching Aether XP (900.0) to reach level 10
        lumina.addXP(900.0, activityType: .aether)
        XCTAssertEqual(lumina.level, 10)
        XCTAssertGreaterThanOrEqual(lumina.aetherXPWeight, 0.70)
        
        guard let evolved = lumina.checkEvolution() else {
            XCTFail("Lumina should be able to evolve at level 10")
            return
        }
        
        XCTAssertEqual(evolved.name, "Evolved Lumina")
        XCTAssertEqual(evolved.level, 10)
        XCTAssertEqual(evolved.focus, lumina.focus + 20.0)
        XCTAssertEqual(evolved.hp, lumina.hp + 20.0)
    }
    
    func testHybridLuminaEvolution() {
        var lumina = Podmon.lumina()
        XCTAssertEqual(lumina.name, "Lumina")
        XCTAssertNil(lumina.checkEvolution())
        
        // Add aether XP and kinetic XP to fall below 0.70 weight
        // Matching aether XP: 400.0
        lumina.addXP(400.0, activityType: .aether)
        
        // Non-matching kinetic XP: 1000.0 (degraded to 500.0 kinetic XP)
        lumina.addXP(1000.0, activityType: .kinetic)
        
        XCTAssertEqual(lumina.level, 10)
        XCTAssertLessThan(lumina.aetherXPWeight, 0.70)
        
        guard let evolved = lumina.checkEvolution() else {
            XCTFail("Lumina should be able to evolve at level 10")
            return
        }
        
        XCTAssertEqual(evolved.name, "Aero Lumina")
        XCTAssertEqual(evolved.level, 10)
        XCTAssertEqual(evolved.focus, lumina.focus + 20.0)
        XCTAssertEqual(evolved.hp, lumina.hp + 20.0)
    }
    
    // MARK: - Level-Up Growth Tests
    
    func testExactStatGrowthPure() {
        var zephyr = Podmon.zephyr()
        
        // Initial stats check
        XCTAssertEqual(zephyr.speed, 15.0)
        XCTAssertEqual(zephyr.agility, 15.0)
        XCTAssertEqual(zephyr.power, 5.0)
        XCTAssertEqual(zephyr.hp, 40.0)
        XCTAssertEqual(zephyr.focus, 5.0)
        XCTAssertEqual(zephyr.special, 5.0)
        
        // Level up once using matching kinetic XP
        zephyr.addXP(100.0, activityType: .kinetic)
        
        XCTAssertEqual(zephyr.level, 2)
        XCTAssertEqual(zephyr.kineticXPWeight, 1.0)
        XCTAssertEqual(zephyr.forgeXPWeight, 0.0)
        XCTAssertEqual(zephyr.aetherXPWeight, 0.0)
        
        // Speed & Agility should get baseline +2, plus +8 * 1.0 / 2 = +4. Total +6.
        XCTAssertEqual(zephyr.speed, 21.0)
        XCTAssertEqual(zephyr.agility, 21.0)
        
        // Power, HP, Focus, Special should get baseline +2, plus +8 * 0.0 = +0. Total +2.
        XCTAssertEqual(zephyr.power, 7.0)
        XCTAssertEqual(zephyr.hp, 42.0) // HP is NOT locked at 40!
        XCTAssertEqual(zephyr.focus, 7.0)
        XCTAssertEqual(zephyr.special, 7.0)
    }
    
    func testExactStatGrowthHybrid() {
        var zephyr = Podmon.zephyr()
        
        // Initial stats check
        XCTAssertEqual(zephyr.speed, 15.0)
        XCTAssertEqual(zephyr.agility, 15.0)
        XCTAssertEqual(zephyr.power, 5.0)
        XCTAssertEqual(zephyr.hp, 40.0)
        XCTAssertEqual(zephyr.focus, 5.0)
        XCTAssertEqual(zephyr.special, 5.0)
        
        // Add 50.0 kinetic XP (matching) -> 50.0 total matching
        zephyr.addXP(50.0, activityType: .kinetic)
        // Add 100.0 forge XP (non-matching) -> 50.0 forge XP. Total 100.0, trigger level up!
        zephyr.addXP(100.0, activityType: .forge)
        
        XCTAssertEqual(zephyr.level, 2)
        XCTAssertEqual(zephyr.kineticXPWeight, 0.5)
        XCTAssertEqual(zephyr.forgeXPWeight, 0.5)
        XCTAssertEqual(zephyr.aetherXPWeight, 0.0)
        
        // Speed & Agility: baseline +2, plus 8.0 * 0.5 / 2 = +2. Total +4.
        XCTAssertEqual(zephyr.speed, 19.0)
        XCTAssertEqual(zephyr.agility, 19.0)
        
        // Power & HP: baseline +2, plus 8.0 * 0.5 / 2 = +2. Total +4.
        XCTAssertEqual(zephyr.power, 9.0)
        XCTAssertEqual(zephyr.hp, 44.0)
        
        // Focus & Special: baseline +2, plus 8.0 * 0.0 = +0. Total +2.
        XCTAssertEqual(zephyr.focus, 7.0)
        XCTAssertEqual(zephyr.special, 7.0)
    }
}
