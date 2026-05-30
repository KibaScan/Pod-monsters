import XCTest
@testable import PodMonsters

@MainActor
final class MeditationTests: XCTestCase {
    
    private var podmonID: UUID!
    
    override func setUp() {
        super.setUp()
        podmonID = UUID()
    }
    
    func testBreathingPatternTimingCalculations() {
        let fourSevenEight = BreathingPattern.fourSevenEight
        XCTAssertEqual(fourSevenEight.inhaleDuration, 4.0)
        XCTAssertEqual(fourSevenEight.holdAfterInhaleDuration, 7.0)
        XCTAssertEqual(fourSevenEight.exhaleDuration, 8.0)
        XCTAssertEqual(fourSevenEight.holdAfterExhaleDuration, 0.0)
        XCTAssertEqual(fourSevenEight.cycleDuration, 19.0)
        XCTAssertEqual(fourSevenEight.totalDuration, 76.0)
        
        let box = BreathingPattern.box
        XCTAssertEqual(box.cycleDuration, 16.0)
        XCTAssertEqual(box.totalDuration, 64.0)
        
        let resonant = BreathingPattern.resonant
        XCTAssertEqual(resonant.cycleDuration, 10.0)
        XCTAssertEqual(resonant.totalDuration, 60.0)
    }
    
    func testMeditationSessionLifecycleAndManualAccumulation() async throws {
        let session = MeditationSession(
            equippedPodmonID: podmonID,
            breathingPattern: .fourSevenEight
        )
        
        XCTAssertEqual(session.type, .meditation)
        XCTAssertEqual(session.equippedPodmonID, podmonID)
        XCTAssertNil(session.startTime)
        XCTAssertNil(session.endTime)
        XCTAssertFalse(session.isRecording)
        
        session.start()
        XCTAssertTrue(session.isRecording)
        XCTAssertNotNil(session.startTime)
        
        // Log heart rates
        session.addHeartRateSample(HeartRateData(bpm: 65.0))
        session.addHeartRateSample(HeartRateData(bpm: 72.0))
        session.addHeartRateSample(HeartRateData(bpm: 68.0))
        
        // Log stillness and HRV
        session.addStillnessScore(0.98)
        session.addStillnessScore(0.96)
        session.addHRVSample(HRVData(sdnnMilliseconds: 75.0))
        session.addHRVSample(HRVData(sdnnMilliseconds: 82.0))
        
        // Complete 2 cycles manually
        session.completeCycle()
        session.completeCycle()
        XCTAssertEqual(session.completedCycles, 2)
        
        // Manual increment of mindful minutes
        session.incrementMindfulMinutes(1.5)
        
        // Expected mindful minutes: 2 * (19 / 60) + 1.5 = 38/60 + 1.5 ≈ 0.633 + 1.5 = 2.133
        let expectedMindful = (19.0 * 2.0 / 60.0) + 1.5
        XCTAssertEqual(session.accumulatedMindfulMinutes, expectedMindful, accuracy: 0.001)
        
        let summary = try await session.finalize()
        
        XCTAssertFalse(session.isRecording)
        XCTAssertNotNil(session.endTime)
        XCTAssertEqual(summary.type, .meditation)
        XCTAssertEqual(summary.equippedPodmonID, podmonID)
        
        // Common signals verification
        XCTAssertEqual(summary.commonSignals.heartRateSamples.count, 3)
        XCTAssertEqual(summary.commonSignals.heartRateRise, 7.0, accuracy: 0.001)
        
        // Check payload decoding
        let payload = try XCTUnwrap(summary.decodeMeditationPayload())
        XCTAssertEqual(payload.breathingPattern.type, .fourSevenEight)
        XCTAssertEqual(payload.completedCycles, 2)
        XCTAssertEqual(payload.stillnessScores, [0.98, 0.96])
        XCTAssertEqual(payload.hrvSamples.count, 2)
        XCTAssertEqual(payload.mindfulMinutes, expectedMindful, accuracy: 0.001)
        
        // Verify elevated VerificationTier (since stillness >= 0.95)
        XCTAssertEqual(summary.effortEnvelope.verificationTier, .verified)
    }
    
    func testMeditationSessionAutoFillMinutesAndLowerStillness() async throws {
        let session = MeditationSession(
            equippedPodmonID: podmonID,
            breathingPattern: .box
        )
        
        session.start()
        // Simulate short session without manual cycle logging
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Log low stillness
        session.addStillnessScore(0.80)
        session.addStillnessScore(0.85)
        
        let summary = try await session.finalize()
        
        // Ensure mindful minutes auto-filled from duration (which should be > 0.0)
        let payload = try XCTUnwrap(summary.decodeMeditationPayload())
        XCTAssertGreaterThan(payload.mindfulMinutes, 0.0)
        XCTAssertEqual(payload.completedCycles, 0)
        
        // Average stillness is 0.825, which is < 0.95 (stillnessThreshold), so it falls back to permissive selfReported
        XCTAssertEqual(summary.effortEnvelope.verificationTier, .selfReported)
    }
    
    func testSerializationRoundTrip() async throws {
        let session = MeditationSession(
            equippedPodmonID: podmonID,
            breathingPattern: .resonant
        )
        
        session.start()
        session.addStillnessScore(0.99)
        session.addHRVSample(HRVData(sdnnMilliseconds: 90.0))
        session.completeCycle()
        
        let summary = try await session.finalize()
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(summary)
        let decodedSummary = try decoder.decode(SessionSummary.self, from: encodedData)
        
        XCTAssertEqual(decodedSummary.type, .meditation)
        XCTAssertEqual(decodedSummary.equippedPodmonID, podmonID)
        
        let payload = try XCTUnwrap(decodedSummary.decodeMeditationPayload())
        XCTAssertEqual(payload.breathingPattern.type, .resonant)
        XCTAssertEqual(payload.completedCycles, 1)
        XCTAssertEqual(payload.stillnessScores, [0.99])
        XCTAssertEqual(payload.hrvSamples.first?.sdnnMilliseconds, 90.0)
    }
    
    func testSensorlessSessionDefaultsToSelfReported() async throws {
        let session = MeditationSession(
            equippedPodmonID: podmonID,
            breathingPattern: .fourSevenEight
        )
        
        session.start()
        
        // Log heart rate only — no stillness, no HRV
        session.addHeartRateSample(HeartRateData(bpm: 62.0))
        session.completeCycle()
        
        let summary = try await session.finalize()
        
        // Without stillness evidence the tier must NOT be promoted to .verified
        XCTAssertEqual(summary.effortEnvelope.verificationTier, .selfReported)
        
        let payload = try XCTUnwrap(summary.decodeMeditationPayload())
        XCTAssertTrue(payload.stillnessScores.isEmpty)
        XCTAssertEqual(payload.completedCycles, 1)
        XCTAssertGreaterThan(payload.mindfulMinutes, 0.0)
    }
}
