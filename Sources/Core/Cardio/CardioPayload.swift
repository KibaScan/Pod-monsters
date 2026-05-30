import Foundation

/// Specific telemetry payload for a cardiovascular workout session.
public struct CardioPayload: Codable, Equatable, Sendable {
    public let totalSteps: Double
    public let totalDistanceMeters: Double
    public let averageCadence: Double // steps per minute
    public let averagePaceSecondsPerKilometer: Double
    public let timeInZones: [HRZone: TimeInterval]
    public let heartRateSamples: [HeartRateData]
    public let maxHeartRateUsed: Double
    public let customZoneRanges: HRZoneRanges?
    
    public init(
        totalSteps: Double,
        totalDistanceMeters: Double,
        averageCadence: Double,
        averagePaceSecondsPerKilometer: Double,
        timeInZones: [HRZone: TimeInterval],
        heartRateSamples: [HeartRateData],
        maxHeartRateUsed: Double,
        customZoneRanges: HRZoneRanges? = nil
    ) {
        self.totalSteps = totalSteps
        self.totalDistanceMeters = totalDistanceMeters
        self.averageCadence = averageCadence
        self.averagePaceSecondsPerKilometer = averagePaceSecondsPerKilometer
        self.timeInZones = timeInZones
        self.heartRateSamples = heartRateSamples
        self.maxHeartRateUsed = maxHeartRateUsed
        self.customZoneRanges = customZoneRanges
    }
    
    /// Returns the average pace formatted as a user-friendly string (MM:SS / km).
    public var formattedPace: String {
        guard averagePaceSecondsPerKilometer > 0 && averagePaceSecondsPerKilometer.isFinite else {
            return "--:--"
        }
        let totalSeconds = Int(round(averagePaceSecondsPerKilometer))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

extension SessionSummary {
    /// Decodes the CardioPayload from this session's payload if applicable.
    public func decodeCardioPayload() -> CardioPayload? {
        guard type == .cardio, payload.typeIdentifier == "cardio_payload" else {
            return nil
        }
        return try? payload.decode(CardioPayload.self)
    }
}
