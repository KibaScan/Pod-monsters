import Foundation

/// A type representing daily steps count signal.
public struct StepsData: Codable, Equatable, Sendable {
    public let count: Double
    
    public init(count: Double) {
        self.count = count
    }
}

/// A type representing daily walking/running distance signal.
public struct DistanceData: Codable, Equatable, Sendable {
    public let meters: Double
    
    public init(meters: Double) {
        self.meters = meters
    }
}

/// A type representing active energy burned signal.
public struct ActiveEnergyData: Codable, Equatable, Sendable {
    public let kilocalories: Double
    
    public init(kilocalories: Double) {
        self.kilocalories = kilocalories
    }
}

/// A type representing heart rate signal.
public struct HeartRateData: Codable, Equatable, Sendable {
    public let bpm: Double
    
    public init(bpm: Double) {
        self.bpm = bpm
    }
}

/// A type representing heart rate variability (HRV) SDNN signal.
public struct HRVData: Codable, Equatable, Sendable {
    public let sdnnMilliseconds: Double
    
    public init(sdnnMilliseconds: Double) {
        self.sdnnMilliseconds = sdnnMilliseconds
    }
}

/// A type representing sleep signals including stages.
public struct SleepData: Codable, Equatable, Sendable {
    public let asleepDurationSeconds: TimeInterval
    public let coreDurationSeconds: TimeInterval?
    public let deepDurationSeconds: TimeInterval?
    public let remDurationSeconds: TimeInterval?
    
    public init(
        asleepDurationSeconds: TimeInterval,
        coreDurationSeconds: TimeInterval? = nil,
        deepDurationSeconds: TimeInterval? = nil,
        remDurationSeconds: TimeInterval? = nil
    ) {
        self.asleepDurationSeconds = asleepDurationSeconds
        self.coreDurationSeconds = coreDurationSeconds
        self.deepDurationSeconds = deepDurationSeconds
        self.remDurationSeconds = remDurationSeconds
    }
}

/// A type representing mindful minutes duration signal.
public struct MindfulMinutesData: Codable, Equatable, Sendable {
    public let minutes: Double
    
    public init(minutes: Double) {
        self.minutes = minutes
    }
}

/// A type representing time spent in daylight signal.
public struct DaylightTimeData: Codable, Equatable, Sendable {
    public let durationSeconds: TimeInterval
    
    public init(durationSeconds: TimeInterval) {
        self.durationSeconds = durationSeconds
    }
}
