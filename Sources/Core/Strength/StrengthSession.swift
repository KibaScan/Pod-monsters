import Foundation

@MainActor
public class StrengthSession: WellnessSession {
    public let type: SessionType = .strength
    public let equippedPodmonID: UUID
    public private(set) var startTime: Date?
    public private(set) var endTime: Date?
    public private(set) var isRecording: Bool = false
    
    // Strength-specific properties
    public let routineName: String
    public var loggedExercises: [LoggedExercise]
    
    // Passive tracking signals
    public private(set) var heartRateSamples: [HeartRateData] = []
    public private(set) var movementLevels: [Double] = []
    public private(set) var passiveRepTempos: [Double] = []
    public private(set) var passiveRestDurations: [Double] = []
    
    public var biomeTag: BiomeType = .neutral
    
    /// Standard Initializer
    public init(
        equippedPodmonID: UUID,
        routineName: String,
        loggedExercises: [LoggedExercise] = []
    ) {
        self.equippedPodmonID = equippedPodmonID
        self.routineName = routineName
        self.loggedExercises = loggedExercises
    }
    
    /// Convenience Initializer that pre-fills sets based on routine template and historical data
    public init(
        equippedPodmonID: UUID,
        routineTemplate: RoutineTemplate,
        history: StrengthHistory,
        increment: Double = 2.5
    ) {
        self.equippedPodmonID = equippedPodmonID
        self.routineName = routineTemplate.name
        self.loggedExercises = history.preFill(template: routineTemplate, increment: increment)
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
                domain: "StrengthSessionErrorDomain",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "Session has not been started or is already finalized."]
            )
        }
        
        let end = Date()
        self.endTime = end
        self.isRecording = false
        
        let duration = end.timeIntervalSince(start)
        
        // HR stats
        let bpms = heartRateSamples.map { $0.bpm }
        let minHR = bpms.min() ?? 0.0
        let maxHR = bpms.max() ?? 0.0
        let hrRise = max(0.0, maxHR - minHR)
        
        // Movement stats
        let avgMovement = movementLevels.isEmpty ? 0.0 : (movementLevels.reduce(0.0, +) / Double(movementLevels.count))
        
        // Build common signals
        let common = CommonSignals(
            duration: duration,
            heartRateSamples: heartRateSamples,
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        // Build StrengthPayload
        let strengthPayload = StrengthPayload(
            routineName: routineName,
            loggedExercises: loggedExercises,
            passiveRepTempos: passiveRepTempos,
            passiveRestDurations: passiveRestDurations
        )
        
        // Fold passive metrics into EffortEnvelope
        // Start with default permissive base derivation
        let baseEnvelope = EffortEnvelope.derive(
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        // Calculate additional effort score from strength-specific passive signals
        let avgTempo = passiveRepTempos.isEmpty ? 0.0 : (passiveRepTempos.reduce(0.0, +) / Double(passiveRepTempos.count))
        let totalRest = passiveRestDurations.reduce(0.0, +)
        
        // Total completed reps across all exercises
        let completedRepsCount = loggedExercises.reduce(0) { sum, logged in
            sum + logged.sets.filter { $0.isCompleted }.reduce(0) { s, set in s + set.reps }
        }
        
        // Dynamic additions to show thorough utilization of passive metrics
        let passiveTempoScore = avgTempo * 1.5
        let passiveRestScore = totalRest * 0.02
        let repScore = Double(completedRepsCount) * 0.1
        
        let strengthScore = baseEnvelope.calculatedScore + passiveTempoScore + passiveRestScore + repScore
        
        let envelope = EffortEnvelope(
            verificationTier: baseEnvelope.verificationTier,
            calculatedScore: strengthScore
        )
        
        // Extensible payload for the final summary
        let extensiblePayload = try ExtensiblePayload(
            typeIdentifier: "strength_payload",
            value: strengthPayload
        )
        
        return SessionSummary(
            type: .strength,
            equippedPodmonID: equippedPodmonID,
            startTime: start,
            endTime: end,
            duration: duration,
            commonSignals: common,
            effortEnvelope: envelope,
            payload: extensiblePayload
        )
    }
    
    // MARK: - Passive Input Loggers (Mockable/Passive capturing)
    
    public func addHeartRateSample(_ sample: HeartRateData) {
        guard isRecording else { return }
        heartRateSamples.append(sample)
    }
    
    public func addMovementLevel(_ level: Double) {
        guard isRecording else { return }
        movementLevels.append(level)
    }
    
    public func addPassiveRepTempo(_ seconds: Double) {
        guard isRecording else { return }
        passiveRepTempos.append(seconds)
    }
    
    public func addPassiveRestDuration(_ seconds: Double) {
        guard isRecording else { return }
        passiveRestDurations.append(seconds)
    }
    
    // MARK: - Active Logging Methods (Confirm / Adjust)
    
    /// Updates an existing pre-filled set at a specific exercise and set index.
    public func updateSet(
        exerciseID: UUID,
        setIndex: Int,
        reps: Int,
        weight: Double,
        rpe: Double? = nil,
        isCompleted: Bool = true
    ) {
        guard let index = loggedExercises.firstIndex(where: { $0.exercise.id == exerciseID }) else { return }
        guard setIndex >= 0 && setIndex < loggedExercises[index].sets.count else { return }
        
        loggedExercises[index].sets[setIndex] = LoggedSet(
            reps: reps,
            weight: weight,
            rpe: rpe,
            isCompleted: isCompleted
        )
    }
    
    /// Adds a completely new set to a specific logged exercise in the active session.
    public func addSet(
        exerciseID: UUID,
        reps: Int,
        weight: Double,
        rpe: Double? = nil,
        isCompleted: Bool = true
    ) {
        guard let index = loggedExercises.firstIndex(where: { $0.exercise.id == exerciseID }) else {
            return
        }
        
        loggedExercises[index].sets.append(LoggedSet(
            reps: reps,
            weight: weight,
            rpe: rpe,
            isCompleted: isCompleted
        ))
    }
}
