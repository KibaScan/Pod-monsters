import Foundation

extension SessionSummary {
    /// Decodes the StrengthPayload from this session's payload if applicable.
    public func decodeStrengthPayload() -> StrengthPayload? {
        guard type == .strength, payload.typeIdentifier == "strength_payload" else {
            return nil
        }
        return try? payload.decode(StrengthPayload.self)
    }
}

public struct StrengthHistory: Codable, Equatable, Sendable {
    public let completedSessions: [SessionSummary]
    
    public init(completedSessions: [SessionSummary] = []) {
        self.completedSessions = completedSessions
    }
    
    /// Finds the last completed sets for the given exercise in chronological history.
    public func lastCompletedSets(for exerciseID: UUID) -> [LoggedSet]? {
        // Iterate backward (most recent first)
        for session in completedSessions.reversed() {
            if let payload = session.decodeStrengthPayload() {
                if let loggedExercise = payload.loggedExercises.first(where: { $0.exercise.id == exerciseID }) {
                    let completed = loggedExercise.sets.filter { $0.isCompleted }
                    if !completed.isEmpty {
                        return completed
                    }
                }
            }
        }
        return nil
    }
    
    /// Finds the historical maximum weight lifted for an exercise.
    public func historicalMaxWeight(for exerciseID: UUID) -> Double? {
        var maxWeight: Double? = nil
        for session in completedSessions {
            if let payload = session.decodeStrengthPayload() {
                if let mw = payload.maxWeights[exerciseID] {
                    maxWeight = max(maxWeight ?? 0.0, mw)
                }
            }
        }
        return maxWeight
    }
    
    /// Finds the historical maximum estimated 1RM for an exercise.
    public func historicalMaxEstimated1RM(for exerciseID: UUID) -> Double? {
        var max1RM: Double? = nil
        for session in completedSessions {
            if let payload = session.decodeStrengthPayload() {
                if let e1rm = payload.estimated1RMs[exerciseID] {
                    max1RM = max(max1RM ?? 0.0, e1rm)
                }
            }
        }
        return max1RM
    }
    
    /// Returns true if `currentWeight` exceeds the historical maximum weight for the exercise.
    public func isNewWeightPR(exerciseID: UUID, currentWeight: Double) -> Bool {
        guard let historicalMax = historicalMaxWeight(for: exerciseID) else {
            // No history at all — any completed lift is the first record.
            return true
        }
        return currentWeight > historicalMax
    }
    
    /// Returns true if `current1RM` exceeds the historical maximum estimated 1RM for the exercise.
    public func isNewEstimated1RMPR(exerciseID: UUID, current1RM: Double) -> Bool {
        guard let historicalMax = historicalMaxEstimated1RM(for: exerciseID) else {
            return true
        }
        return current1RM > historicalMax
    }
    
    /// Generates pre-filled LoggedExercises for a RoutineTemplate based on progressive overload principles.
    /// Suggestions increase the last weight lifted by a small configurable increment.
    public func preFill(template: RoutineTemplate, increment: Double = 2.5) -> [LoggedExercise] {
        var loggedExercises: [LoggedExercise] = []
        
        for exerciseTemplate in template.exercises {
            let exercise = exerciseTemplate.exercise
            let targetSets = exerciseTemplate.targetSets
            
            var loggedSets: [LoggedSet] = []
            
            if let lastSets = lastCompletedSets(for: exercise.id), !lastSets.isEmpty {
                // Pre-fill sets based on history and progressive-overload
                for i in 0..<targetSets {
                    // If we have history for this index, use it. Otherwise, repeat the last available set.
                    let historicalSet = i < lastSets.count ? lastSets[i] : lastSets.last!
                    let suggestedWeight = historicalSet.weight + increment
                    
                    loggedSets.append(LoggedSet(
                        reps: historicalSet.reps,
                        weight: suggestedWeight,
                        rpe: historicalSet.rpe,
                        isCompleted: true // prefilled is ready to be confirmed
                    ))
                }
            } else {
                // No history: prefill with safe default values (e.g. 10 reps, 0.0 weight) for clean "confirm or adjust" log
                for _ in 0..<targetSets {
                    loggedSets.append(LoggedSet(
                        reps: 10,
                        weight: 0.0,
                        rpe: nil,
                        isCompleted: true
                    ))
                }
            }
            
            loggedExercises.append(LoggedExercise(exercise: exercise, sets: loggedSets))
        }
        
        return loggedExercises
    }
}
