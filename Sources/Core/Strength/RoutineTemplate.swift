import Foundation

public struct ExerciseTemplate: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID { exercise.id }
    public let exercise: Exercise
    public let targetSets: Int
    
    public init(exercise: Exercise, targetSets: Int) {
        self.exercise = exercise
        self.targetSets = targetSets
    }
}

public struct RoutineTemplate: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let exercises: [ExerciseTemplate]
    
    public init(id: UUID = UUID(), name: String, description: String, exercises: [ExerciseTemplate]) {
        self.id = id
        self.name = name
        self.description = description
        self.exercises = exercises
    }
}
