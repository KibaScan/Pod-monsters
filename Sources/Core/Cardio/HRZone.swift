import Foundation

/// Defines the intensity zones for cardiovascular exercise.
public enum HRZone: String, Codable, CaseIterable, Equatable, Sendable {
    case zone1 = "Zone 1 (Warm Up)"
    case zone2 = "Zone 2 (Easy)"
    case zone3 = "Zone 3 (Aerobic)"
    case zone4 = "Zone 4 (Anaerobic)"
    case zone5 = "Zone 5 (Max)"
}

/// Manages the configuration and boundary check logic for heart rate zones.
public struct HRZoneRanges: Codable, Equatable, Sendable {
    public let zone1Lower: Double
    public let zone2Lower: Double
    public let zone3Lower: Double
    public let zone4Lower: Double
    public let zone5Lower: Double
    
    public init(
        zone1Lower: Double,
        zone2Lower: Double,
        zone3Lower: Double,
        zone4Lower: Double,
        zone5Lower: Double
    ) {
        self.zone1Lower = zone1Lower
        self.zone2Lower = zone2Lower
        self.zone3Lower = zone3Lower
        self.zone4Lower = zone4Lower
        self.zone5Lower = zone5Lower
    }
    
    /// Generates default zone boundaries based on maximum heart rate (Max HR)
    public static func defaultForMaxHR(_ maxHR: Double) -> HRZoneRanges {
        return HRZoneRanges(
            zone1Lower: maxHR * 0.50,
            zone2Lower: maxHR * 0.60,
            zone3Lower: maxHR * 0.70,
            zone4Lower: maxHR * 0.80,
            zone5Lower: maxHR * 0.90
        )
    }
    
    /// Classifies a heart rate (BPM) into an HRZone. Returns nil if below Zone 1 (active recovery/rest).
    public func classify(_ bpm: Double) -> HRZone? {
        guard bpm.isFinite else { return nil }
        if bpm >= zone5Lower {
            return .zone5
        } else if bpm >= zone4Lower {
            return .zone4
        } else if bpm >= zone3Lower {
            return .zone3
        } else if bpm >= zone2Lower {
            return .zone2
        } else if bpm >= zone1Lower {
            return .zone1
        }
        return nil
    }
}
