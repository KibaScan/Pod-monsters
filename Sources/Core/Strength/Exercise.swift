import Foundation

public enum ExerciseCategory: String, CaseIterable, Codable, Sendable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core
    case fullBody
}

public enum EquipmentType: String, CaseIterable, Codable, Sendable {
    case barbell
    case dumbbell
    case machine
    case bodyweight
    case cables
    case kettlebell
    case bands
}

public struct Exercise: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: ExerciseCategory
    public let equipment: EquipmentType
    
    public init(id: UUID = UUID(), name: String, category: ExerciseCategory, equipment: EquipmentType) {
        self.id = id
        self.name = name
        self.category = category
        self.equipment = equipment
    }
}
