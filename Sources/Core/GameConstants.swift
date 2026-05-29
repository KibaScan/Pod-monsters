import Foundation

public struct GameConstants {
    // Deduplication/Precision windows
    public static let precision: Int = 4
    
    // Patience decays
    public static let patienceDecay: Double = 0.05
    
    // Ideal breathing rate
    public static let idealBreathingRate: Double = 6.0
    
    // Stillness and HRV thresholds
    public static let stillnessThreshold: Double = 0.95
    public static let hrvTolerance: Double = 5.0
    
    // Solar elevation limits
    public static let solarLowerLimit: Double = -15.0
    public static let solarUpperLimit: Double = 15.0
    
    // Cache TTL
    public static let cacheTTL: TimeInterval = 900.0
    
    // Posture angle thresholds
    public static let postureGoodAngle: Double = 15.0
    public static let postureExtremeAngle: Double = 45.0
    
    // Posture XP values
    public static let postureGoodXP: Double = 1.0
    public static let postureDegradedXP: Double = 0.2
    
    // Capture success XP
    public static let captureSuccessXP: Double = 50.0
    
    // Release podmon XP
    public static let releasePodmonXP: Double = 500.0
    
    // Other Game Constants (from hardcoded values in FishingEngine)
    public static let maxLineTension: Double = 1.0
    public static let minLineTension: Double = 0.0
    public static let hookSetTension: Double = 0.3
    public static let excellentBreathingThreshold: Double = 0.8
    public static let poorBreathingThreshold: Double = 0.3
    public static let tensionReductionMultiplier: Double = 0.15
    public static let tensionIncreaseMultiplier: Double = 0.25
    public static let reelingTensionIncrease: Double = 0.15
    public static let captureBreathingThreshold: Double = 0.9
    public static let captureMaxTension: Double = 0.3
}

public struct CatchResult: Equatable {
    public let name: String
    public let faction: Faction
    
    public init(name: String, faction: Faction) {
        self.name = name
        self.faction = faction
    }
}

public struct CatchTable {
    public static func lookup(biome: BiomeType, bait: BaitType) -> CatchResult {
        switch (biome, bait) {
        // Water Biome
        case (.water, .mindBeads):
            return CatchResult(name: "Aqua Spirit", faction: .aether)
        case (.water, .spinnerLures), (.water, .masterLures):
            return CatchResult(name: "River Dart", faction: .kinetic)
        case (.water, .ironHooks):
            return CatchResult(name: "Rust Barnacle", faction: .forge)
            
        // Green Space Biome
        case (.greenSpace, .spinnerLures), (.greenSpace, .masterLures):
            return CatchResult(name: "Leaf Sprite", faction: .kinetic)
        case (.greenSpace, .mindBeads):
            return CatchResult(name: "Grove Pixie", faction: .aether)
        case (.greenSpace, .ironHooks):
            return CatchResult(name: "Iron Sprout", faction: .forge)
            
        // Urban Biome
        case (.urban, .ironHooks):
            return CatchResult(name: "Street Racer", faction: .forge)
        case (.urban, .spinnerLures), (.urban, .masterLures):
            return CatchResult(name: "Neon Swallow", faction: .kinetic)
        case (.urban, .mindBeads):
            return CatchResult(name: "Cyber Sprite", faction: .aether)
            
        // Gym Biome
        case (.gym, .ironHooks):
            return CatchResult(name: "Concrete Golem", faction: .forge)
        case (.gym, .spinnerLures), (.gym, .masterLures):
            return CatchResult(name: "Aero Boulder", faction: .kinetic)
        case (.gym, .mindBeads):
            return CatchResult(name: "Zen Pebble", faction: .aether)
            
        // Fallback Mechanism
        default:
            return CatchResult(name: "Wild Puddle Sprite", faction: .kinetic)
        }
    }
}
