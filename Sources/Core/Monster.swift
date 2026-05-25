import Foundation

public struct Monster: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var faction: Faction
    public var level: Int
    public var xp: Double
    
    public var kineticXP: Double
    public var forgeXP: Double
    public var aetherXP: Double
    
    public var kineticXPWeight: Double
    public var forgeXPWeight: Double
    public var aetherXPWeight: Double
    
    public var speed: Double
    public var agility: Double
    public var power: Double
    public var hp: Double
    public var focus: Double
    public var special: Double
    
    public init(
        id: UUID = UUID(),
        name: String,
        faction: Faction,
        level: Int = 1,
        xp: Double = 0.0,
        kineticXP: Double = 0.0,
        forgeXP: Double = 0.0,
        aetherXP: Double = 0.0,
        kineticXPWeight: Double = 0.0,
        forgeXPWeight: Double = 0.0,
        aetherXPWeight: Double = 0.0,
        speed: Double = 10.0,
        agility: Double = 10.0,
        power: Double = 10.0,
        hp: Double = 100.0,
        focus: Double = 10.0,
        special: Double = 10.0
    ) {
        self.id = id
        self.name = name
        self.faction = faction
        self.level = level
        self.xp = xp
        self.kineticXP = kineticXP
        self.forgeXP = forgeXP
        self.aetherXP = aetherXP
        self.kineticXPWeight = kineticXPWeight
        self.forgeXPWeight = forgeXPWeight
        self.aetherXPWeight = aetherXPWeight
        self.speed = speed
        self.agility = agility
        self.power = power
        self.hp = hp
        self.focus = focus
        self.special = special
    }
    
    // Starter templates
    public static func zephyr() -> Monster {
        return Monster(
            name: "Zephyr",
            faction: .kinetic,
            level: 1,
            xp: 0.0,
            kineticXP: 0.0,
            forgeXP: 0.0,
            aetherXP: 0.0,
            kineticXPWeight: 1.0,
            forgeXPWeight: 0.0,
            aetherXPWeight: 0.0,
            speed: 15.0,
            agility: 15.0,
            power: 5.0,
            hp: 40.0,
            focus: 5.0,
            special: 5.0
        )
    }
    
    public static func basalt() -> Monster {
        return Monster(
            name: "Basalt",
            faction: .forge,
            level: 1,
            xp: 0.0,
            kineticXP: 0.0,
            forgeXP: 0.0,
            aetherXP: 0.0,
            kineticXPWeight: 0.0,
            forgeXPWeight: 1.0,
            aetherXPWeight: 0.0,
            speed: 5.0,
            agility: 5.0,
            power: 15.0,
            hp: 60.0,
            focus: 5.0,
            special: 5.0
        )
    }
    
    public static func lumina() -> Monster {
        return Monster(
            name: "Lumina",
            faction: .aether,
            level: 1,
            xp: 0.0,
            kineticXP: 0.0,
            forgeXP: 0.0,
            aetherXP: 0.0,
            kineticXPWeight: 0.0,
            forgeXPWeight: 0.0,
            aetherXPWeight: 1.0,
            speed: 5.0,
            agility: 5.0,
            power: 5.0,
            hp: 45.0,
            focus: 15.0,
            special: 15.0
        )
    }
    
    public mutating func addXP(_ amount: Double, activityType: Faction) {
        if level >= 100 {
            xp = 0.0
            return
        }
        
        let finalAmount: Double
        if activityType != faction {
            finalAmount = amount * 0.5
        } else {
            finalAmount = amount
        }
        
        xp += finalAmount
        switch activityType {
        case .kinetic:
            kineticXP += finalAmount
        case .forge:
            forgeXP += finalAmount
        case .aether:
            aetherXP += finalAmount
        }
        
        let totalFactionXP = kineticXP + forgeXP + aetherXP
        if totalFactionXP > 0 {
            kineticXPWeight = kineticXP / totalFactionXP
            forgeXPWeight = forgeXP / totalFactionXP
            aetherXPWeight = aetherXP / totalFactionXP
        }
        
        while level < 100 && xp >= 100.0 {
            xp -= 100.0
            level += 1
            
            // Baseline growth of +2 to all 6 stats
            speed += 2.0
            agility += 2.0
            power += 2.0
            hp += 2.0
            focus += 2.0
            special += 2.0
            
            // Weighted growth of +8 distributed based on faction weights
            let kineticPoints = 8.0 * kineticXPWeight
            let forgePoints = 8.0 * forgeXPWeight
            let aetherPoints = 8.0 * aetherXPWeight
            
            speed += kineticPoints / 2.0
            agility += kineticPoints / 2.0
            
            power += forgePoints / 2.0
            hp += forgePoints / 2.0
            
            focus += aetherPoints / 2.0
            special += aetherPoints / 2.0
        }
        
        if level >= 100 {
            level = 100
            xp = 0.0
        }
    }
    
    public func checkEvolution() -> Monster? {
        guard level >= 10 else { return nil }
        guard name == "Zephyr" || name == "Basalt" || name == "Lumina" else { return nil }
        
        var evolved = self
        
        if name == "Zephyr" {
            if kineticXPWeight >= 0.70 {
                evolved.name = "Evolved Zephyr"
            } else {
                evolved.name = "Titan Zephyr"
            }
            evolved.speed += 20.0
            evolved.agility += 20.0
            evolved.power += 20.0
            evolved.hp += 20.0
            evolved.focus += 20.0
            evolved.special += 20.0
            return evolved
        } else if name == "Basalt" {
            if forgeXPWeight >= 0.70 {
                evolved.name = "Evolved Basalt"
            } else {
                evolved.name = "Monk Basalt"
            }
            evolved.speed += 20.0
            evolved.agility += 20.0
            evolved.power += 20.0
            evolved.hp += 20.0
            evolved.focus += 20.0
            evolved.special += 20.0
            return evolved
        } else if name == "Lumina" {
            if aetherXPWeight >= 0.70 {
                evolved.name = "Evolved Lumina"
            } else {
                evolved.name = "Aero Lumina"
            }
            evolved.speed += 20.0
            evolved.agility += 20.0
            evolved.power += 20.0
            evolved.hp += 20.0
            evolved.focus += 20.0
            evolved.special += 20.0
            return evolved
        }
        
        return nil
    }
}
