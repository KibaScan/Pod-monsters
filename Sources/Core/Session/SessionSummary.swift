import Foundation

extension BiomeType: @unchecked Sendable {}

public struct CommonSignals: Codable, Equatable, Sendable {
    public let duration: TimeInterval
    public let heartRateSamples: [HeartRateData]
    public let heartRateRise: Double
    public let movementLevel: Double
    public let biomeTag: BiomeType
    
    public init(
        duration: TimeInterval,
        heartRateSamples: [HeartRateData],
        heartRateRise: Double,
        movementLevel: Double,
        biomeTag: BiomeType
    ) {
        self.duration = duration
        self.heartRateSamples = heartRateSamples
        self.heartRateRise = heartRateRise
        self.movementLevel = movementLevel
        self.biomeTag = biomeTag
    }
}

public struct ExtensiblePayload: Codable, Equatable, Sendable {
    public let typeIdentifier: String
    public let rawData: Data
    
    public init(typeIdentifier: String, rawData: Data) {
        self.typeIdentifier = typeIdentifier
        self.rawData = rawData
    }
    
    public init<T: Codable & Equatable & Sendable>(typeIdentifier: String, value: T) throws {
        self.typeIdentifier = typeIdentifier
        self.rawData = try JSONEncoder().encode(value)
    }
    
    public func decode<T: Codable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: rawData)
    }
}

public struct SessionSummary: Codable, Equatable, Sendable {
    public let type: SessionType
    public let equippedPodmonID: UUID
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let commonSignals: CommonSignals
    public let effortEnvelope: EffortEnvelope
    public let payload: ExtensiblePayload
    
    public init(
        type: SessionType,
        equippedPodmonID: UUID,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        commonSignals: CommonSignals,
        effortEnvelope: EffortEnvelope,
        payload: ExtensiblePayload
    ) {
        self.type = type
        self.equippedPodmonID = equippedPodmonID
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.commonSignals = commonSignals
        self.effortEnvelope = effortEnvelope
        self.payload = payload
    }
}
