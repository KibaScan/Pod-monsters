import Foundation

@MainActor
public class MeditationSession: WellnessSession {
    public let type: SessionType = .meditation
    public let equippedPodmonID: UUID
    public private(set) var startTime: Date?
    public private(set) var endTime: Date?
    public private(set) var isRecording: Bool = false
    
    // Mindfulness properties
    public let breathingPattern: BreathingPattern
    public private(set) var completedCycles: Int = 0
    
    // In-session signals
    public private(set) var heartRateSamples: [HeartRateData] = []
    public private(set) var movementLevels: [Double] = []
    public private(set) var stillnessScores: [Double] = []
    public private(set) var hrvSamples: [HRVData] = []
    
    public var biomeTag: BiomeType = .neutral
    public private(set) var accumulatedMindfulMinutes: Double = 0.0
    
    /// Standard Initializer
    public init(
        equippedPodmonID: UUID,
        breathingPattern: BreathingPattern = .fourSevenEight
    ) {
        self.equippedPodmonID = equippedPodmonID
        self.breathingPattern = breathingPattern
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
                domain: "MeditationSessionErrorDomain",
                code: 101,
                userInfo: [NSLocalizedDescriptionKey: "Session is not active or already finalized."]
            )
        }
        
        let end = Date()
        self.endTime = end
        self.isRecording = false
        
        let duration = end.timeIntervalSince(start)
        
        // Auto-fill mindful minutes if no cycle completions or manual logging occurred
        let finalMindfulMinutes = accumulatedMindfulMinutes > 0.0 ? accumulatedMindfulMinutes : (duration / 60.0)
        
        // Heart rate rise
        let bpms = heartRateSamples.map { $0.bpm }
        let minHR = bpms.min() ?? 0.0
        let maxHR = bpms.max() ?? 0.0
        let hrRise = max(0.0, maxHR - minHR)
        
        // Resolve movement level: standard or mapped from stillness
        let avgMovement: Double
        if !movementLevels.isEmpty {
            avgMovement = movementLevels.reduce(0.0, +) / Double(movementLevels.count)
        } else if !stillnessScores.isEmpty {
            let avgStillness = stillnessScores.reduce(0.0, +) / Double(stillnessScores.count)
            avgMovement = max(0.0, 1.0 - avgStillness) * 2.0
        } else {
            avgMovement = 0.0
        }
        
        // Build common signals
        let common = CommonSignals(
            duration: duration,
            heartRateSamples: heartRateSamples,
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        // Calculate passive stillness and HRV metrics
        // Default to 0.0 when no data: insufficient evidence should not grant .verified
        let avgStillness = stillnessScores.isEmpty ? 0.0 : (stillnessScores.reduce(0.0, +) / Double(stillnessScores.count))
        let avgHRV = hrvSamples.isEmpty ? 60.0 : (hrvSamples.reduce(0.0) { $0 + $1.sdnnMilliseconds } / Double(hrvSamples.count))
        
        // Effort base derivation (permissive)
        let baseEnvelope = EffortEnvelope.derive(
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        // Custom meditation verification override based on stillness focus
        var tier = baseEnvelope.verificationTier
        if avgStillness >= GameConstants.stillnessThreshold {
            tier = .verified
        }
        
        // Custom relaxation effort score calculation
        let hrvScorePart = avgHRV * 0.4
        let stillnessScorePart = avgStillness * 12.0
        let cycleScorePart = Double(completedCycles) * 3.0
        let calculatedScore = max(0.0, baseEnvelope.calculatedScore + hrvScorePart + stillnessScorePart + cycleScorePart)
        
        let envelope = EffortEnvelope(
            verificationTier: tier,
            calculatedScore: calculatedScore
        )
        
        // Prepare meditation-specific payload
        let meditationPayload = MeditationPayload(
            breathingPattern: breathingPattern,
            completedCycles: completedCycles,
            stillnessScores: stillnessScores,
            hrvSamples: hrvSamples,
            mindfulMinutes: finalMindfulMinutes
        )
        
        let extensiblePayload = try ExtensiblePayload(
            typeIdentifier: "meditation_payload",
            value: meditationPayload
        )
        
        return SessionSummary(
            type: .meditation,
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
    
    public func addHeartRateSample(_ sample: HeartRateData) {
        guard isRecording else { return }
        heartRateSamples.append(sample)
    }
    
    public func addMovementLevel(_ level: Double) {
        guard isRecording else { return }
        movementLevels.append(level)
    }
    
    public func addStillnessScore(_ score: Double) {
        guard isRecording else { return }
        stillnessScores.append(score)
    }
    
    public func addHRVSample(_ sample: HRVData) {
        guard isRecording else { return }
        hrvSamples.append(sample)
    }
    
    /// Increments completed breathing cycles and aggregates cycle duration to mindful minutes.
    public func completeCycle() {
        guard isRecording else { return }
        self.completedCycles += 1
        self.accumulatedMindfulMinutes += breathingPattern.cycleDuration / 60.0
    }
    
    /// Manually registers an arbitrary amount of mindful minutes.
    public func incrementMindfulMinutes(_ minutes: Double) {
        guard isRecording else { return }
        self.accumulatedMindfulMinutes += minutes
    }
}
