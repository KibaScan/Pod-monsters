import Foundation

@MainActor
public class CardioSession: WellnessSession {
    public let type: SessionType = .cardio
    public let equippedPodmonID: UUID
    public private(set) var startTime: Date?
    public private(set) var endTime: Date?
    public private(set) var isRecording: Bool = false
    
    // Configurable thresholds/boundaries
    public let maxHeartRate: Double
    public let zoneRanges: HRZoneRanges
    
    // In-session signals
    public private(set) var stepsSamples: [StepsData] = []
    public private(set) var distanceSamples: [DistanceData] = []
    public private(set) var heartRateSamples: [HeartRateData] = []
    public private(set) var movementLevels: [Double] = []
    
    public var biomeTag: BiomeType = .neutral
    
    /// Standard Initializer
    public init(
        equippedPodmonID: UUID,
        maxHeartRate: Double = 190.0,
        customZoneRanges: HRZoneRanges? = nil
    ) {
        self.equippedPodmonID = equippedPodmonID
        self.maxHeartRate = maxHeartRate
        self.zoneRanges = customZoneRanges ?? HRZoneRanges.defaultForMaxHR(maxHeartRate)
    }
    
    /// Internal seam for deterministic test-date injection.
    /// Accessible in tests via `@testable import PodMonsters`.
    internal func setTimesForTesting(start: Date, end: Date) {
        self.startTime = start
        self.endTime = end
    }
    
    // MARK: - WellnessSession Lifecycle Methods
    
    public func start() {
        guard !isRecording else { return }
        self.startTime = Date()
        self.isRecording = true
    }
    
    public func finalize() async throws -> SessionSummary {
        guard isRecording, let start = startTime else {
            throw NSError(
                domain: "CardioSessionErrorDomain",
                code: 201,
                userInfo: [NSLocalizedDescriptionKey: "Session is not active or already finalized."]
            )
        }
        
        let end = endTime ?? Date()
        self.endTime = end
        self.isRecording = false
        
        let duration = max(0.0, end.timeIntervalSince(start))
        
        // Aggregate distance & steps
        let totalSteps = stepsSamples.reduce(0.0) { $0 + $1.count }
        let totalDistanceMeters = distanceSamples.reduce(0.0) { $0 + $1.meters }
        
        // Calculate average cadence (steps per minute)
        let durationMinutes = duration / 60.0
        let averageCadence = durationMinutes > 0 ? (totalSteps / durationMinutes) : 0.0
        
        // Calculate average pace (seconds per kilometer)
        let distanceKilometers = totalDistanceMeters / 1000.0
        let averagePaceSecondsPerKilometer = distanceKilometers > 0 ? (duration / distanceKilometers) : 0.0
        
        // Heart rate rise
        let bpms = heartRateSamples.map { $0.bpm }
        let minHR = bpms.min() ?? 0.0
        let maxHR = bpms.max() ?? 0.0
        let hrRise = max(0.0, maxHR - minHR)
        
        // Resolve movement level: standard average or derived from step cadence
        let avgMovement: Double
        if !movementLevels.isEmpty {
            avgMovement = movementLevels.reduce(0.0, +) / Double(movementLevels.count)
        } else if averageCadence > 0 {
            // A cadence of 100 steps/min maps to a 2.0 movement level
            avgMovement = averageCadence / 50.0
        } else {
            avgMovement = 0.0
        }
        
        // Derive standard base EffortEnvelope (permissive)
        let baseEnvelope = EffortEnvelope.derive(
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        // Calculate HR-zone classification breakdown
        var zoneBreakdown: [HRZone: TimeInterval] = [:]
        for zone in HRZone.allCases {
            zoneBreakdown[zone] = 0.0
        }
        
        if !heartRateSamples.isEmpty {
            let timePerSample = duration / Double(heartRateSamples.count)
            for sample in heartRateSamples {
                if let zone = zoneRanges.classify(sample.bpm) {
                    zoneBreakdown[zone, default: 0.0] += timePerSample
                }
            }
        }
        
        // Custom Cardio verification logic:
        // Must have recorded heart rate data to verify sensor authenticity, and meet thresholds
        var tier = baseEnvelope.verificationTier
        if !heartRateSamples.isEmpty && totalDistanceMeters >= 500.0 && averageCadence >= 80.0 {
            tier = .verified
        }
        
        // Custom cardio effort score contribution
        // 10 pts per km, 5 pts per 1,000 steps, and zone duration multipliers (converted to minutes)
        let distanceScore = totalDistanceMeters / 100.0
        let stepsScore = totalSteps / 200.0
        
        let zone3Minutes = zoneBreakdown[.zone3, default: 0.0] / 60.0
        let zone4Minutes = zoneBreakdown[.zone4, default: 0.0] / 60.0
        let zone5Minutes = zoneBreakdown[.zone5, default: 0.0] / 60.0
        let hrIntensityScore = (zone3Minutes * 2.0) + (zone4Minutes * 3.0) + (zone5Minutes * 4.0)
        
        let calculatedScore = max(0.0, baseEnvelope.calculatedScore + distanceScore + stepsScore + hrIntensityScore)
        
        let envelope = EffortEnvelope(
            verificationTier: tier,
            calculatedScore: calculatedScore
        )
        
        // Prepare specific Cardio payload
        let cardioPayload = CardioPayload(
            totalSteps: totalSteps,
            totalDistanceMeters: totalDistanceMeters,
            averageCadence: averageCadence,
            averagePaceSecondsPerKilometer: averagePaceSecondsPerKilometer,
            timeInZones: zoneBreakdown,
            heartRateSamples: heartRateSamples,
            maxHeartRateUsed: maxHeartRate,
            customZoneRanges: zoneRanges
        )
        
        let extensiblePayload = try ExtensiblePayload(
            typeIdentifier: "cardio_payload",
            value: cardioPayload
        )
        
        // Build common signals
        let common = CommonSignals(
            duration: duration,
            heartRateSamples: heartRateSamples,
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        return SessionSummary(
            type: .cardio,
            equippedPodmonID: equippedPodmonID,
            startTime: start,
            endTime: end,
            duration: duration,
            commonSignals: common,
            effortEnvelope: envelope,
            payload: extensiblePayload
        )
    }
    
    // MARK: - In-Session Logging Methods
    
    public func addStepsSample(_ sample: StepsData) {
        guard isRecording else { return }
        stepsSamples.append(sample)
    }
    
    public func addSteps(_ count: Double) {
        guard isRecording else { return }
        stepsSamples.append(StepsData(count: count))
    }
    
    public func addDistanceSample(_ sample: DistanceData) {
        guard isRecording else { return }
        distanceSamples.append(sample)
    }
    
    public func addDistance(_ meters: Double) {
        guard isRecording else { return }
        distanceSamples.append(DistanceData(meters: meters))
    }
    
    public func addHeartRateSample(_ sample: HeartRateData) {
        guard isRecording else { return }
        heartRateSamples.append(sample)
    }
    
    public func addMovementLevel(_ level: Double) {
        guard isRecording else { return }
        movementLevels.append(level)
    }
}
