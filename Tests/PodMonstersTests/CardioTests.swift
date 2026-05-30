import XCTest
@testable import PodMonsters

@MainActor
final class CardioTests: XCTestCase {
    
    private var podmonID: UUID!
    
    override func setUp() {
        super.setUp()
        podmonID = UUID()
    }
    
    func testHRZoneClassificationAtBoundaries() {
        // Default Max HR = 190.0
        // Zone 1: [95.0, 114.0)
        // Zone 2: [114.0, 133.0)
        // Zone 3: [133.0, 152.0)
        // Zone 4: [152.0, 171.0)
        // Zone 5: [171.0, infinity)
        let defaultRanges = HRZoneRanges.defaultForMaxHR(190.0)
        
        // Below Zone 1
        XCTAssertNil(defaultRanges.classify(94.9))
        XCTAssertNil(defaultRanges.classify(80.0))
        
        // Zone 1 boundaries
        XCTAssertEqual(defaultRanges.classify(95.0), .zone1)
        XCTAssertEqual(defaultRanges.classify(113.9), .zone1)
        
        // Zone 2 boundaries
        XCTAssertEqual(defaultRanges.classify(114.0), .zone2)
        XCTAssertEqual(defaultRanges.classify(132.9), .zone2)
        
        // Zone 3 boundaries
        XCTAssertEqual(defaultRanges.classify(133.0), .zone3)
        XCTAssertEqual(defaultRanges.classify(151.9), .zone3)
        
        // Zone 4 boundaries
        XCTAssertEqual(defaultRanges.classify(152.0), .zone4)
        XCTAssertEqual(defaultRanges.classify(170.9), .zone4)
        
        // Zone 5 boundaries
        XCTAssertEqual(defaultRanges.classify(171.0), .zone5)
        XCTAssertEqual(defaultRanges.classify(200.0), .zone5)
        
        // Custom Ranges
        let customRanges = HRZoneRanges(
            zone1Lower: 100.0,
            zone2Lower: 120.0,
            zone3Lower: 140.0,
            zone4Lower: 160.0,
            zone5Lower: 180.0
        )
        XCTAssertNil(customRanges.classify(99.0))
        XCTAssertEqual(customRanges.classify(100.0), .zone1)
        XCTAssertEqual(customRanges.classify(125.0), .zone2)
        XCTAssertEqual(customRanges.classify(145.0), .zone3)
        XCTAssertEqual(customRanges.classify(165.0), .zone4)
        XCTAssertEqual(customRanges.classify(185.0), .zone5)
    }
    
    func testInfinityAndNaNBPMReturnsNil() {
        let ranges = HRZoneRanges.defaultForMaxHR(190.0)
        
        // +infinity must NOT classify as zone5
        XCTAssertNil(ranges.classify(.infinity))
        // -infinity must NOT classify as any zone
        XCTAssertNil(ranges.classify(-.infinity))
        // NaN must NOT classify as any zone
        XCTAssertNil(ranges.classify(.nan))
    }
    
    func testCardioSessionLifecycleAndAggregation() async throws {
        let session = CardioSession(
            equippedPodmonID: podmonID,
            maxHeartRate: 200.0 // Default zones based on 200.0 Max HR
        )
        
        XCTAssertEqual(session.type, .cardio)
        XCTAssertEqual(session.equippedPodmonID, podmonID)
        XCTAssertNil(session.startTime)
        XCTAssertNil(session.endTime)
        XCTAssertFalse(session.isRecording)
        
        session.start()
        XCTAssertTrue(session.isRecording)
        XCTAssertNotNil(session.startTime)
        
        // Deterministic 10-minute window via internal test seam
        let now = Date()
        session.setTimesForTesting(start: now.addingTimeInterval(-600), end: now)
        
        // Log steps: 3 samples of 400 steps = 1200 steps total
        session.addStepsSample(StepsData(count: 400.0))
        session.addSteps(400.0)
        session.addStepsSample(StepsData(count: 400.0))
        
        // Log distance: 3 samples of 300 meters = 900 meters total
        session.addDistanceSample(DistanceData(meters: 300.0))
        session.addDistance(300.0)
        session.addDistanceSample(DistanceData(meters: 300.0))
        
        // Log HR samples
        // Max HR = 200.0
        // Zone 1: [100.0, 120.0)
        // Zone 2: [120.0, 140.0)
        // Zone 3: [140.0, 160.0)
        // Zone 4: [160.0, 180.0)
        // Zone 5: [180.0, infinity)
        session.addHeartRateSample(HeartRateData(bpm: 110.0)) // Zone 1
        session.addHeartRateSample(HeartRateData(bpm: 130.0)) // Zone 2
        session.addHeartRateSample(HeartRateData(bpm: 150.0)) // Zone 3
        session.addHeartRateSample(HeartRateData(bpm: 170.0)) // Zone 4
        session.addHeartRateSample(HeartRateData(bpm: 190.0)) // Zone 5
        
        // Log custom movement levels
        session.addMovementLevel(2.5)
        session.addMovementLevel(3.5)
        
        let summary = try await session.finalize()
        
        XCTAssertFalse(session.isRecording)
        XCTAssertNotNil(session.endTime)
        XCTAssertEqual(summary.type, .cardio)
        XCTAssertEqual(summary.equippedPodmonID, podmonID)
        
        // Aggregated Metrics Verification
        let payload = try XCTUnwrap(summary.decodeCardioPayload())
        XCTAssertEqual(payload.totalSteps, 1200.0)
        XCTAssertEqual(payload.totalDistanceMeters, 900.0)
        XCTAssertEqual(payload.maxHeartRateUsed, 200.0)
        XCTAssertEqual(payload.heartRateSamples.count, 5)
        
        // 1200 steps / 10 minutes = 120.0 steps/min
        XCTAssertEqual(payload.averageCadence, 120.0, accuracy: 0.001)
        // 600 seconds / 0.9 kilometers = 666.666... seconds/kilometer
        XCTAssertEqual(payload.averagePaceSecondsPerKilometer, 666.667, accuracy: 0.01)
        
        // Formatted pace format validation: 667 rounded seconds = 11 mins 7 secs
        XCTAssertEqual(payload.formattedPace, "11:07/km")
        
        // HR Zone classification breakdown verification
        // Check that time was accumulated for all 5 zones equally (120 seconds per zone)
        XCTAssertEqual(payload.timeInZones[.zone1] ?? 0.0, 120.0, accuracy: 0.001)
        XCTAssertEqual(payload.timeInZones[.zone2] ?? 0.0, 120.0, accuracy: 0.001)
        XCTAssertEqual(payload.timeInZones[.zone3] ?? 0.0, 120.0, accuracy: 0.001)
        XCTAssertEqual(payload.timeInZones[.zone4] ?? 0.0, 120.0, accuracy: 0.001)
        XCTAssertEqual(payload.timeInZones[.zone5] ?? 0.0, 120.0, accuracy: 0.001)
        
        // Heart rate rise = 190.0 - 110.0 = 80.0
        XCTAssertEqual(summary.commonSignals.heartRateRise, 80.0, accuracy: 0.001)
        
        // Movement Level = (2.5 + 3.5) / 2 = 3.0
        XCTAssertEqual(summary.commonSignals.movementLevel, 3.0, accuracy: 0.001)
    }
    
    func testCardioSessionVerificationTierPromotion() async throws {
        let now = Date()
        
        // Case 1: Meets all criteria for verified tier:
        // Heart Rate present, distance >= 500.0 meters, average cadence >= 80.0 steps/min
        let verifiedSession = CardioSession(equippedPodmonID: podmonID)
        verifiedSession.start()
        verifiedSession.setTimesForTesting(start: now.addingTimeInterval(-600), end: now)
        
        // Log steps and distance to yield cadence >= 80 and distance >= 500m
        verifiedSession.addSteps(1000.0) // 100 steps/min
        verifiedSession.addDistance(600.0)
        verifiedSession.addHeartRateSample(HeartRateData(bpm: 140.0))
        
        let summary1 = try await verifiedSession.finalize()
        XCTAssertEqual(summary1.effortEnvelope.verificationTier, .verified)
        
        // Case 2: Low distance (fails >= 500.0m criteria)
        let lowDistanceSession = CardioSession(equippedPodmonID: podmonID)
        lowDistanceSession.start()
        lowDistanceSession.setTimesForTesting(start: now.addingTimeInterval(-600), end: now)
        lowDistanceSession.addSteps(1000.0)
        lowDistanceSession.addDistance(400.0) // 400m
        lowDistanceSession.addHeartRateSample(HeartRateData(bpm: 140.0))
        let summary2 = try await lowDistanceSession.finalize()
        XCTAssertEqual(summary2.effortEnvelope.verificationTier, .selfReported)
        
        // Case 3: Low steps/cadence (fails >= 80.0 cadence criteria)
        let lowCadenceSession = CardioSession(equippedPodmonID: podmonID)
        lowCadenceSession.start()
        lowCadenceSession.setTimesForTesting(start: now.addingTimeInterval(-600), end: now)
        lowCadenceSession.addSteps(5.0) // 5 steps / 10 mins = 0.5 steps/min
        lowCadenceSession.addDistance(600.0)
        lowCadenceSession.addHeartRateSample(HeartRateData(bpm: 140.0))
        
        let summary3 = try await lowCadenceSession.finalize()
        let payload3 = try XCTUnwrap(summary3.decodeCardioPayload())
        XCTAssertLessThan(payload3.averageCadence, 80.0)
        XCTAssertEqual(summary3.effortEnvelope.verificationTier, .selfReported)
    }
    
    func testCardioPayloadSerializationRoundTrip() async throws {
        let session = CardioSession(equippedPodmonID: podmonID)
        session.start()
        session.addSteps(500.0)
        session.addDistance(400.0)
        session.addHeartRateSample(HeartRateData(bpm: 135.0))
        
        let summary = try await session.finalize()
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(summary)
        let decodedSummary = try decoder.decode(SessionSummary.self, from: encodedData)
        
        XCTAssertEqual(decodedSummary.type, .cardio)
        XCTAssertEqual(decodedSummary.equippedPodmonID, podmonID)
        
        let payload = try XCTUnwrap(decodedSummary.decodeCardioPayload())
        XCTAssertEqual(payload.totalSteps, 500.0)
        XCTAssertEqual(payload.totalDistanceMeters, 400.0)
        XCTAssertEqual(payload.heartRateSamples.first?.bpm, 135.0)
    }
    
    func testSensorlessSessionFallback() async throws {
        let now = Date()
        let session = CardioSession(equippedPodmonID: podmonID)
        session.start()
        session.setTimesForTesting(start: now.addingTimeInterval(-300), end: now)
        
        // No heart rate data, no movement levels logged
        session.addSteps(300.0)
        session.addDistance(200.0)
        
        let summary = try await session.finalize()
        
        // Verification tier must NOT be verified because no HR samples exist
        XCTAssertEqual(summary.effortEnvelope.verificationTier, .selfReported)
        
        // Movement level should be derived from cadence (300 / 5 mins = 60 steps/min. 60 / 50 = 1.2)
        XCTAssertEqual(summary.commonSignals.movementLevel, 1.2, accuracy: 0.001)
    }
    
    func testReversedTimeSessionClampsToZeroDuration() async throws {
        let now = Date()
        let session = CardioSession(equippedPodmonID: podmonID)
        session.start()
        // Inject reversed times: end is 10 minutes BEFORE start
        session.setTimesForTesting(start: now, end: now.addingTimeInterval(-600))
        
        session.addSteps(500.0)
        session.addDistance(1000.0)
        session.addHeartRateSample(HeartRateData(bpm: 150.0))
        
        let summary = try await session.finalize()
        
        // Duration must clamp to zero — never negative
        XCTAssertEqual(summary.duration, 0.0)
        
        let payload = try XCTUnwrap(summary.decodeCardioPayload())
        
        // With zero duration: cadence and pace must be zero, not negative
        XCTAssertEqual(payload.averageCadence, 0.0)
        XCTAssertEqual(payload.averagePaceSecondsPerKilometer, 0.0)
        XCTAssertEqual(payload.formattedPace, "--:--")
        
        // Steps and distance still aggregate correctly
        XCTAssertEqual(payload.totalSteps, 500.0)
        XCTAssertEqual(payload.totalDistanceMeters, 1000.0)
        
        // Zone breakdown should be empty (zero time per sample)
        for zone in HRZone.allCases {
            XCTAssertEqual(payload.timeInZones[zone] ?? 0.0, 0.0)
        }
        
        // Effort score must be non-negative
        XCTAssertGreaterThanOrEqual(summary.effortEnvelope.calculatedScore, 0.0)
    }
}
