import Foundation

public enum Faction: String, CaseIterable, Codable {
    case kinetic
    case forge
    case aether
}

public enum BaitType: String, CaseIterable, Codable {
    case ironHooks
    case spinnerLures
    case mindBeads
    case masterLures
    
    public func associatedFaction() -> Faction? {
        switch self {
        case .ironHooks:
            return .forge
        case .spinnerLures:
            return .kinetic
        case .mindBeads:
            return .aether
        case .masterLures:
            return nil
        }
    }
}
