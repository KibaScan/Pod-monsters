import Foundation

public enum VerificationTier: String, Codable, CaseIterable, Equatable, Sendable {
    case verified
    case selfReported
    case unverified
}

public struct EffortEnvelope: Codable, Equatable, Sendable {
    public let verificationTier: VerificationTier
    public let calculatedScore: Double
    
    // Threshold Constants
    public static let minHeartRateRiseForVerified: Double = 15.0
    public static let minMovementLevelForVerified: Double = 2.0
    
    public init(verificationTier: VerificationTier, calculatedScore: Double) {
        self.verificationTier = verificationTier
        self.calculatedScore = calculatedScore
    }
    
    /// Derives the verification tier and calculated score based on HR rise, movement level, and context.
    /// Default implementation is permissive, guaranteeing at least .selfReported.
    public static func derive(
        heartRateRise: Double,
        movementLevel: Double,
        biomeTag: BiomeType
    ) -> EffortEnvelope {
        // Permissive: Default to at least .selfReported
        var tier = VerificationTier.selfReported
        
        let score = (heartRateRise * 1.5) + (movementLevel * 2.0)
        
        if heartRateRise >= minHeartRateRiseForVerified && movementLevel >= minMovementLevelForVerified {
            tier = .verified
        }
        
        return EffortEnvelope(verificationTier: tier, calculatedScore: score)
    }
}
