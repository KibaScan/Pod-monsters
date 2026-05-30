import Foundation

public enum BreathingPatternType: String, Codable, CaseIterable, Sendable {
    case box
    case fourSevenEight
    case resonant
    case custom
}

public enum BreathingPhase: String, Codable, CaseIterable, Sendable {
    case inhale
    case holdAfterInhale
    case exhale
    case holdAfterExhale
}

public struct BreathingPattern: Codable, Equatable, Sendable {
    public let type: BreathingPatternType
    public let name: String
    public let inhaleDuration: TimeInterval
    public let holdAfterInhaleDuration: TimeInterval
    public let exhaleDuration: TimeInterval
    public let holdAfterExhaleDuration: TimeInterval
    public let targetCycles: Int
    
    public init(
        type: BreathingPatternType,
        name: String,
        inhaleDuration: TimeInterval,
        holdAfterInhaleDuration: TimeInterval,
        exhaleDuration: TimeInterval,
        holdAfterExhaleDuration: TimeInterval,
        targetCycles: Int
    ) {
        self.type = type
        self.name = name
        self.inhaleDuration = inhaleDuration
        self.holdAfterInhaleDuration = holdAfterInhaleDuration
        self.exhaleDuration = exhaleDuration
        self.holdAfterExhaleDuration = holdAfterExhaleDuration
        self.targetCycles = targetCycles
    }
    
    public var cycleDuration: TimeInterval {
        return inhaleDuration + holdAfterInhaleDuration + exhaleDuration + holdAfterExhaleDuration
    }
    
    public var totalDuration: TimeInterval {
        return cycleDuration * Double(targetCycles)
    }
    
    /// Preconfigured 4-7-8 breathing pattern (4s inhale, 7s hold, 8s exhale, 0s hold, 4 cycles).
    public static var fourSevenEight: BreathingPattern {
        return BreathingPattern(
            type: .fourSevenEight,
            name: "4-7-8 Breathing",
            inhaleDuration: 4.0,
            holdAfterInhaleDuration: 7.0,
            exhaleDuration: 8.0,
            holdAfterExhaleDuration: 0.0,
            targetCycles: 4
        )
    }
    
    /// Preconfigured Box breathing pattern (4s inhale, 4s hold, 4s exhale, 4s hold, 4 cycles).
    public static var box: BreathingPattern {
        return BreathingPattern(
            type: .box,
            name: "Box Breathing",
            inhaleDuration: 4.0,
            holdAfterInhaleDuration: 4.0,
            exhaleDuration: 4.0,
            holdAfterExhaleDuration: 4.0,
            targetCycles: 4
        )
    }
    
    /// Preconfigured Resonant breathing pattern (5s inhale, 0s hold, 5s exhale, 0s hold, 6 cycles).
    public static var resonant: BreathingPattern {
        return BreathingPattern(
            type: .resonant,
            name: "Resonant Breathing",
            inhaleDuration: 5.0,
            holdAfterInhaleDuration: 0.0,
            exhaleDuration: 5.0,
            holdAfterExhaleDuration: 0.0,
            targetCycles: 6
        )
    }
}
