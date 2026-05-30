import Foundation

public enum SessionType: String, CaseIterable, Codable, Sendable {
    case cardio
    case strength
    case meditation
    
    public var associatedFaction: Faction {
        switch self {
        case .cardio: return .kinetic
        case .strength: return .forge
        case .meditation: return .aether
        }
    }
}
