import Foundation

public struct LoggedSet: Codable, Equatable, Sendable {
    public var reps: Int
    public var weight: Double
    public var rpe: Double?
    public var isCompleted: Bool
    
    public init(reps: Int, weight: Double, rpe: Double? = nil, isCompleted: Bool = true) {
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isCompleted = isCompleted
    }
}

public struct LoggedExercise: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID { exercise.id }
    public let exercise: Exercise
    public var sets: [LoggedSet]
    
    public init(exercise: Exercise, sets: [LoggedSet] = []) {
        self.exercise = exercise
        self.sets = sets
    }
    
    /// Computes the total volume (Σ reps * weight) for this exercise.
    public var totalVolume: Double {
        sets.filter { $0.isCompleted }.reduce(0.0) { sum, set in
            sum + (Double(set.reps) * set.weight)
        }
    }
    
    /// Finds the maximum weight completed for this exercise in this session.
    public var maxWeight: Double? {
        sets.filter { $0.isCompleted }.map { $0.weight }.max()
    }
    
    /// Computes the max estimated 1RM for this exercise in this session using the Epley formula:
    /// 1RM = w * (1 + r / 30.0) (only valid for r >= 1)
    public var estimated1RM: Double? {
        sets.filter { $0.isCompleted && $0.reps >= 1 }
            .map { set in
                if set.reps == 1 {
                    return set.weight
                } else {
                    return set.weight * (1.0 + Double(set.reps) / 30.0)
                }
            }
            .max()
    }
}

public struct StrengthPayload: Codable, Equatable, Sendable {
    public let routineName: String
    public let loggedExercises: [LoggedExercise]
    public let totalVolume: Double
    public let passiveRepTempos: [Double]
    public let passiveRestDurations: [Double]
    public let maxWeights: [UUID: Double]
    public let estimated1RMs: [UUID: Double]
    
    public init(
        routineName: String,
        loggedExercises: [LoggedExercise],
        passiveRepTempos: [Double] = [],
        passiveRestDurations: [Double] = []
    ) {
        self.routineName = routineName
        self.loggedExercises = loggedExercises
        self.passiveRepTempos = passiveRepTempos
        self.passiveRestDurations = passiveRestDurations
        
        var total = 0.0
        var maxW: [UUID: Double] = [:]
        var e1RM: [UUID: Double] = [:]
        
        for logged in loggedExercises {
            total += logged.totalVolume
            if let mw = logged.maxWeight {
                maxW[logged.exercise.id] = mw
            }
            if let er = logged.estimated1RM {
                e1RM[logged.exercise.id] = er
            }
        }
        
        self.totalVolume = total
        self.maxWeights = maxW
        self.estimated1RMs = e1RM
    }
}
