import XCTest
@testable import PodMonsters

@MainActor
final class StrengthTests: XCTestCase {
    
    private var squat: Exercise!
    private var benchPress: Exercise!
    private var deadlift: Exercise!
    private var legsTemplate: RoutineTemplate!
    private var podmonID: UUID!
    
    override func setUp() {
        super.setUp()
        
        squat = Exercise(name: "Barbell Squat", category: .legs, equipment: .barbell)
        benchPress = Exercise(name: "Bench Press", category: .chest, equipment: .barbell)
        deadlift = Exercise(name: "Deadlift", category: .back, equipment: .barbell)
        
        let squatTemplate = ExerciseTemplate(exercise: squat, targetSets: 3)
        let deadliftTemplate = ExerciseTemplate(exercise: deadlift, targetSets: 2)
        
        legsTemplate = RoutineTemplate(
            name: "Leg & Back Power",
            description: "A strength routine featuring squats and deadlifts.",
            exercises: [squatTemplate, deadliftTemplate]
        )
        
        podmonID = UUID()
    }
    
    func testInitialPrefillAndManualLogging() async throws {
        let history = StrengthHistory()
        
        // Initial session with empty history
        let session = StrengthSession(
            equippedPodmonID: podmonID,
            routineTemplate: legsTemplate,
            history: history
        )
        
        XCTAssertEqual(session.routineName, "Leg & Back Power")
        XCTAssertEqual(session.loggedExercises.count, 2)
        
        // Verify default sets were created
        let squatLogged = session.loggedExercises.first(where: { $0.exercise.id == squat.id })
        XCTAssertNotNil(squatLogged)
        XCTAssertEqual(squatLogged?.sets.count, 3)
        XCTAssertEqual(squatLogged?.sets[0].reps, 10)
        XCTAssertEqual(squatLogged?.sets[0].weight, 0.0)
        
        // Adjust values in-session ("Confirm or adjust")
        session.updateSet(exerciseID: squat.id, setIndex: 0, reps: 5, weight: 135.0, rpe: 8.0)
        session.updateSet(exerciseID: squat.id, setIndex: 1, reps: 5, weight: 135.0, rpe: 8.0)
        session.updateSet(exerciseID: squat.id, setIndex: 2, reps: 5, weight: 140.0, rpe: 9.0)
        
        let deadliftLogged = session.loggedExercises.first(where: { $0.exercise.id == deadlift.id })
        XCTAssertNotNil(deadliftLogged)
        XCTAssertEqual(deadliftLogged?.sets.count, 2)
        
        session.updateSet(exerciseID: deadlift.id, setIndex: 0, reps: 3, weight: 225.0, rpe: 7.5)
        session.updateSet(exerciseID: deadlift.id, setIndex: 1, reps: 3, weight: 225.0, rpe: 8.0)
        
        // Verify local calculations
        let updatedSquat = session.loggedExercises.first(where: { $0.exercise.id == squat.id })!
        XCTAssertEqual(updatedSquat.totalVolume, (5 * 135.0) + (5 * 135.0) + (5 * 140.0))
        XCTAssertEqual(updatedSquat.maxWeight, 140.0)
        
        // 1RM calculation: 140 * (1 + 5 / 30.0) = 140 * 1.16666 = 163.333
        XCTAssertEqual(updatedSquat.estimated1RM!, 140.0 * (1.0 + 5.0 / 30.0), accuracy: 0.001)
        
        // Start and finalize session
        session.start()
        let summary = try await session.finalize()
        
        XCTAssertEqual(summary.type, .strength)
        XCTAssertEqual(summary.equippedPodmonID, podmonID)
        
        let strengthPayload = summary.decodeStrengthPayload()
        XCTAssertNotNil(strengthPayload)
        XCTAssertEqual(strengthPayload?.routineName, "Leg & Back Power")
        XCTAssertEqual(strengthPayload?.totalVolume, updatedSquat.totalVolume + ((3 * 225.0) + (3 * 225.0)))
        XCTAssertEqual(strengthPayload?.maxWeights[squat.id], 140.0)
        XCTAssertEqual(strengthPayload?.maxWeights[deadlift.id], 225.0)
    }
    
    func testProgressiveOverloadPrefillAndPRs() async throws {
        // Step 1: Create a historical session and finalize it
        let firstSession = StrengthSession(equippedPodmonID: podmonID, routineName: "Leg & Back Power")
        
        // Log Squat: 3 sets of 5 reps at 135 lbs
        let loggedSquat = LoggedExercise(exercise: squat, sets: [
            LoggedSet(reps: 5, weight: 135.0, rpe: 8.0),
            LoggedSet(reps: 5, weight: 135.0, rpe: 8.0),
            LoggedSet(reps: 4, weight: 135.0, rpe: 9.0) // failed last rep
        ])
        firstSession.loggedExercises = [loggedSquat]
        
        firstSession.start()
        let firstSummary = try await firstSession.finalize()
        
        // Step 2: Build history from first summary
        let history = StrengthHistory(completedSessions: [firstSummary])
        
        XCTAssertEqual(history.historicalMaxWeight(for: squat.id), 135.0)
        XCTAssertEqual(try XCTUnwrap(history.historicalMaxEstimated1RM(for: squat.id)), 135.0 * (1.0 + 5.0 / 30.0), accuracy: 0.001)
        XCTAssertNil(history.historicalMaxWeight(for: deadlift.id))
        
        // Step 3: Start a second session using template & history (overload increment = 5.0)
        let secondSession = StrengthSession(
            equippedPodmonID: podmonID,
            routineTemplate: legsTemplate,
            history: history,
            increment: 5.0
        )
        
        XCTAssertEqual(secondSession.loggedExercises.count, 2)
        
        let secondSquat = secondSession.loggedExercises.first(where: { $0.exercise.id == squat.id })!
        XCTAssertEqual(secondSquat.sets.count, 3)
        
        // Overload suggestion: last weight (135.0) + 5.0 = 140.0
        // Set 0 suggestion
        XCTAssertEqual(secondSquat.sets[0].weight, 140.0)
        XCTAssertEqual(secondSquat.sets[0].reps, 5)
        
        // Set 1 suggestion
        XCTAssertEqual(secondSquat.sets[1].weight, 140.0)
        XCTAssertEqual(secondSquat.sets[1].reps, 5)
        
        // Set 2 suggestion (index 2 matched historical index 2's reps: 4)
        XCTAssertEqual(secondSquat.sets[2].weight, 140.0)
        XCTAssertEqual(secondSquat.sets[2].reps, 4)
        
        // Deadlift had no history, should have default prefilled values
        let secondDeadlift = secondSession.loggedExercises.first(where: { $0.exercise.id == deadlift.id })!
        XCTAssertEqual(secondDeadlift.sets.count, 2)
        XCTAssertEqual(secondDeadlift.sets[0].weight, 0.0)
        XCTAssertEqual(secondDeadlift.sets[0].reps, 10)
    }
    
    func testPassiveCaptureAndEffortEnvelope() async throws {
        let session = StrengthSession(equippedPodmonID: podmonID, routineName: "Chest Routine")
        session.loggedExercises = [
            LoggedExercise(exercise: benchPress, sets: [
                LoggedSet(reps: 10, weight: 135.0, rpe: 8.0)
            ])
        ]
        
        session.start()
        
        // Accumulate passive metrics
        session.addHeartRateSample(HeartRateData(bpm: 70.0))
        session.addHeartRateSample(HeartRateData(bpm: 95.0)) // Rise = 25.0
        session.addMovementLevel(2.0)
        session.addMovementLevel(4.0) // Avg movement = 3.0
        
        // Rep tempos and rest durations
        session.addPassiveRepTempo(2.5)
        session.addPassiveRepTempo(3.0) // Avg tempo = 2.75
        session.addPassiveRestDuration(60.0) // Rest = 60.0
        
        session.biomeTag = .gym
        
        let summary = try await session.finalize()
        
        XCTAssertEqual(summary.commonSignals.heartRateRise, 25.0)
        XCTAssertEqual(summary.commonSignals.movementLevel, 3.0)
        
        // Check that verification tier correctly reaches `.verified` (Rise >= 15.0 and Movement >= 2.0)
        XCTAssertEqual(summary.effortEnvelope.verificationTier, .verified)
        
        // Base effort score = (heartRateRise * 1.5) + (movementLevel * 2.0) = (25.0 * 1.5) + (3.0 * 2.0) = 37.5 + 6.0 = 43.5
        // Passive tempos addition = 2.75 * 1.5 = 4.125
        // Passive rest addition = 60.0 * 0.02 = 1.2
        // Rep count addition = 10 * 0.1 = 1.0
        // Expected total score = 43.5 + 4.125 + 1.2 + 1.0 = 49.825
        XCTAssertEqual(summary.effortEnvelope.calculatedScore, 49.825, accuracy: 0.001)
        
        // Verify passive lists are recorded in decoded payload
        let payload = try XCTUnwrap(summary.decodeStrengthPayload())
        XCTAssertEqual(payload.passiveRepTempos, [2.5, 3.0])
        XCTAssertEqual(payload.passiveRestDurations, [60.0])
    }
    
    func testCodableRoundTripAndExtensibility() async throws {
        let firstSession = StrengthSession(equippedPodmonID: podmonID, routineName: "Legs")
        firstSession.loggedExercises = [
            LoggedExercise(exercise: squat, sets: [
                LoggedSet(reps: 8, weight: 185.0, rpe: 9.0)
            ])
        ]
        
        firstSession.start()
        firstSession.addHeartRateSample(HeartRateData(bpm: 80.0))
        firstSession.addHeartRateSample(HeartRateData(bpm: 110.0))
        firstSession.addMovementLevel(2.5)
        firstSession.addPassiveRepTempo(2.8)
        firstSession.addPassiveRestDuration(90.0)
        
        let summary = try await firstSession.finalize()
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(summary)
        let decoded = try decoder.decode(SessionSummary.self, from: data)
        
        XCTAssertEqual(decoded.type, .strength)
        XCTAssertEqual(decoded.equippedPodmonID, podmonID)
        
        let strengthPayload = try XCTUnwrap(decoded.decodeStrengthPayload())
        XCTAssertEqual(strengthPayload.routineName, "Legs")
        XCTAssertEqual(strengthPayload.totalVolume, 8 * 185.0)
        XCTAssertEqual(strengthPayload.maxWeights[squat.id], 185.0)
        XCTAssertEqual(strengthPayload.passiveRepTempos, [2.8])
        XCTAssertEqual(strengthPayload.passiveRestDurations, [90.0])
    }
    
    func testPRDetection() async throws {
        // Build a session with a known squat max of 135 lbs
        let firstSession = StrengthSession(equippedPodmonID: podmonID, routineName: "PR Test")
        firstSession.loggedExercises = [
            LoggedExercise(exercise: squat, sets: [
                LoggedSet(reps: 5, weight: 135.0)
            ])
        ]
        firstSession.start()
        let firstSummary = try await firstSession.finalize()
        let history = StrengthHistory(completedSessions: [firstSummary])
        
        // Weight PR checks
        XCTAssertTrue(history.isNewWeightPR(exerciseID: squat.id, currentWeight: 140.0))
        XCTAssertFalse(history.isNewWeightPR(exerciseID: squat.id, currentWeight: 135.0))
        XCTAssertFalse(history.isNewWeightPR(exerciseID: squat.id, currentWeight: 100.0))
        
        // No history for deadlift — any weight is a PR
        XCTAssertTrue(history.isNewWeightPR(exerciseID: deadlift.id, currentWeight: 50.0))
        
        // Estimated 1RM PR checks  (historical: 135 * (1 + 5/30) ≈ 157.5)
        let historical1RM = 135.0 * (1.0 + 5.0 / 30.0)
        XCTAssertTrue(history.isNewEstimated1RMPR(exerciseID: squat.id, current1RM: historical1RM + 1.0))
        XCTAssertFalse(history.isNewEstimated1RMPR(exerciseID: squat.id, current1RM: historical1RM - 1.0))
    }
}
