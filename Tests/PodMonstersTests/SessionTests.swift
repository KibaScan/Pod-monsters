import XCTest
@testable import PodMonsters

@MainActor
final class TestWellnessSession: WellnessSession {
    let type: SessionType
    let equippedPodmonID: UUID
    private(set) var startTime: Date?
    private(set) var endTime: Date?
    private(set) var isRecording: Bool = false
    
    private(set) var heartRateSamples: [HeartRateData] = []
    private(set) var movementLevels: [Double] = []
    var biomeTag: BiomeType = .neutral
    
    init(type: SessionType, equippedPodmonID: UUID) {
        self.type = type
        self.equippedPodmonID = equippedPodmonID
    }
    
    func start() {
        self.startTime = Date()
        self.isRecording = true
    }
    
    func addHeartRateSample(_ sample: HeartRateData) {
        guard isRecording else { return }
        heartRateSamples.append(sample)
    }
    
    func addMovementLevel(_ level: Double) {
        guard isRecording else { return }
        movementLevels.append(level)
    }
    
    func finalize() async throws -> SessionSummary {
        guard isRecording, let start = startTime else {
            throw NSError(domain: "TestWellnessSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session is not active"])
        }
        
        self.endTime = Date()
        self.isRecording = false
        
        let end = self.endTime!
        let duration = end.timeIntervalSince(start)
        
        let minHR = heartRateSamples.map { $0.bpm }.min() ?? 0.0
        let maxHR = heartRateSamples.map { $0.bpm }.max() ?? 0.0
        let hrRise = max(0.0, maxHR - minHR)
        
        let avgMovement = movementLevels.isEmpty ? 0.0 : (movementLevels.reduce(0.0, +) / Double(movementLevels.count))
        
        let common = CommonSignals(
            duration: duration,
            heartRateSamples: heartRateSamples,
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        let envelope = EffortEnvelope.derive(
            heartRateRise: hrRise,
            movementLevel: avgMovement,
            biomeTag: biomeTag
        )
        
        let payload = try ExtensiblePayload(typeIdentifier: "test_string_payload", value: "CustomSessionData")
        
        return SessionSummary(
            type: type,
            equippedPodmonID: equippedPodmonID,
            startTime: start,
            endTime: end,
            duration: duration,
            commonSignals: common,
            effortEnvelope: envelope,
            payload: payload
        )
    }
}

struct MockWorkoutPayload: Codable, Equatable, Sendable {
    let exerciseName: String
    let setsCount: Int
    let totalReps: Int
}

final class SessionTests: XCTestCase {
    
    @MainActor
    func testSessionLifecycleAndSignals() async throws {
        let podmon = Podmon.zephyr()
        let session = TestWellnessSession(type: .cardio, equippedPodmonID: podmon.id)
        
        XCTAssertEqual(session.type, .cardio)
        XCTAssertEqual(session.equippedPodmonID, podmon.id)
        XCTAssertNil(session.startTime)
        XCTAssertFalse(session.isRecording)
        
        session.start()
        XCTAssertTrue(session.isRecording)
        XCTAssertNotNil(session.startTime)
        
        session.addHeartRateSample(HeartRateData(bpm: 72))
        session.addHeartRateSample(HeartRateData(bpm: 95))
        session.addMovementLevel(1.5)
        session.addMovementLevel(2.5)
        
        let summary = try await session.finalize()
        
        XCTAssertFalse(session.isRecording)
        XCTAssertNotNil(session.endTime)
        XCTAssertEqual(summary.type, .cardio)
        XCTAssertEqual(summary.equippedPodmonID, podmon.id)
        XCTAssertEqual(summary.commonSignals.heartRateSamples.count, 2)
        XCTAssertEqual(summary.commonSignals.heartRateRise, 23.0, accuracy: 0.001)
        XCTAssertEqual(summary.commonSignals.movementLevel, 2.0, accuracy: 0.001)
    }
    
    func testSessionSummaryCodableRoundTrip() async throws {
        let podmonID = UUID()
        let start = Date()
        let end = start.addingTimeInterval(300)
        
        let common = CommonSignals(
            duration: 300,
            heartRateSamples: [HeartRateData(bpm: 70), HeartRateData(bpm: 85)],
            heartRateRise: 15.0,
            movementLevel: 2.5,
            biomeTag: .greenSpace
        )
        
        let envelope = EffortEnvelope(verificationTier: .verified, calculatedScore: 25.0)
        
        let workoutPayload = MockWorkoutPayload(exerciseName: "Squat", setsCount: 3, totalReps: 30)
        let extensiblePayload = try ExtensiblePayload(typeIdentifier: "workout_payload", value: workoutPayload)
        
        let summary = SessionSummary(
            type: .strength,
            equippedPodmonID: podmonID,
            startTime: start,
            endTime: end,
            duration: 300,
            commonSignals: common,
            effortEnvelope: envelope,
            payload: extensiblePayload
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(summary)
        let decoded = try decoder.decode(SessionSummary.self, from: data)
        
        XCTAssertEqual(decoded.type, .strength)
        XCTAssertEqual(decoded.equippedPodmonID, podmonID)
        XCTAssertEqual(decoded.duration, 300)
        XCTAssertEqual(decoded.commonSignals.biomeTag, .greenSpace)
        XCTAssertEqual(decoded.commonSignals.heartRateRise, 15.0)
        XCTAssertEqual(decoded.effortEnvelope.verificationTier, .verified)
        XCTAssertEqual(decoded.payload.typeIdentifier, "workout_payload")
        
        let decodedPayload = try decoded.payload.decode(MockWorkoutPayload.self)
        XCTAssertEqual(decodedPayload, workoutPayload)
    }
    
    func testPermissiveEffortEnvelopeDerivation() {
        // Below verified thresholds, should fall back to .selfReported (since it is permissive)
        let envelopeSelf = EffortEnvelope.derive(heartRateRise: 5.0, movementLevel: 1.0, biomeTag: .urban)
        XCTAssertEqual(envelopeSelf.verificationTier, .selfReported)
        XCTAssertEqual(envelopeSelf.calculatedScore, (5.0 * 1.5) + (1.0 * 2.0))
        
        // Meeting both thresholds should yield .verified
        let envelopeVerified = EffortEnvelope.derive(
            heartRateRise: EffortEnvelope.minHeartRateRiseForVerified,
            movementLevel: EffortEnvelope.minMovementLevelForVerified,
            biomeTag: .gym
        )
        XCTAssertEqual(envelopeVerified.verificationTier, .verified)
    }
}
