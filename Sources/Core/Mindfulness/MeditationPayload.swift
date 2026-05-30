import Foundation

public struct MeditationPayload: Codable, Equatable, Sendable {
    public let breathingPattern: BreathingPattern
    public let completedCycles: Int
    public let stillnessScores: [Double]
    public let hrvSamples: [HRVData]
    public let mindfulMinutes: Double
    
    public init(
        breathingPattern: BreathingPattern,
        completedCycles: Int,
        stillnessScores: [Double],
        hrvSamples: [HRVData],
        mindfulMinutes: Double
    ) {
        self.breathingPattern = breathingPattern
        self.completedCycles = completedCycles
        self.stillnessScores = stillnessScores
        self.hrvSamples = hrvSamples
        self.mindfulMinutes = mindfulMinutes
    }
}

extension SessionSummary {
    /// Decodes the MeditationPayload from this session's payload if applicable.
    public func decodeMeditationPayload() -> MeditationPayload? {
        guard type == .meditation, payload.typeIdentifier == "meditation_payload" else {
            return nil
        }
        return try? payload.decode(MeditationPayload.self)
    }
}
