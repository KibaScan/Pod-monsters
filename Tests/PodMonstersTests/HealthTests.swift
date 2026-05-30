import XCTest
@testable import PodMonsters

final class HealthTests: XCTestCase {
    
    // MARK: - Mock Provider Tests
    
    func testMockProviderAuthorizationSuccess() async throws {
        let provider = MockHealthDataProvider()
        provider.authorizationResult = true
        
        let authorized = try await provider.requestAuthorization()
        XCTAssertTrue(authorized)
    }
    
    func testMockProviderAuthorizationFailure() async throws {
        let provider = MockHealthDataProvider()
        provider.authorizationResult = false
        
        let authorized = try await provider.requestAuthorization()
        XCTAssertFalse(authorized)
    }
    
    func testMockProviderThrowsOnError() async throws {
        let provider = MockHealthDataProvider()
        provider.shouldFail = true
        let now = Date()
        
        do {
            _ = try await provider.requestAuthorization()
            XCTFail("Authorization should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchDailySteps(on: now)
            XCTFail("Steps should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchDailyDistance(on: now)
            XCTFail("Distance should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchDailyActiveEnergy(on: now)
            XCTFail("Active energy should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchHeartRate(start: now, end: now)
            XCTFail("Heart rate should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchHRV(start: now, end: now)
            XCTFail("HRV should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchSleep(start: now, end: now)
            XCTFail("Sleep should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchMindfulMinutes(start: now, end: now)
            XCTFail("Mindful minutes should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
        
        do {
            _ = try await provider.fetchTimeInDaylight(start: now, end: now)
            XCTFail("Time in daylight should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "MockHealthDataProvider")
        }
    }

    
    func testMockProviderSignalsFetch() async throws {
        let provider = MockHealthDataProvider()
        let now = Date()
        
        // Steps
        provider.stepsResult = StepsData(count: 8420)
        let steps = try await provider.fetchDailySteps(on: now)
        XCTAssertEqual(steps.count, 8420)
        
        // Distance
        provider.distanceResult = DistanceData(meters: 4200.5)
        let distance = try await provider.fetchDailyDistance(on: now)
        XCTAssertEqual(distance.meters, 4200.5)
        
        // Active Energy
        provider.activeEnergyResult = ActiveEnergyData(kilocalories: 310.2)
        let energy = try await provider.fetchDailyActiveEnergy(on: now)
        XCTAssertEqual(energy.kilocalories, 310.2)
        
        // Heart Rate
        provider.heartRateResult = HeartRateData(bpm: 78.5)
        let hr = try await provider.fetchHeartRate(start: now, end: now)
        XCTAssertEqual(hr.bpm, 78.5)
        
        // HRV
        provider.hrvResult = HRVData(sdnnMilliseconds: 72.1)
        let hrv = try await provider.fetchHRV(start: now, end: now)
        XCTAssertEqual(hrv.sdnnMilliseconds, 72.1)
        
        // Sleep
        provider.sleepResult = SleepData(
            asleepDurationSeconds: 26000,
            coreDurationSeconds: 15000,
            deepDurationSeconds: 6000,
            remDurationSeconds: 5000
        )
        let sleep = try await provider.fetchSleep(start: now, end: now)
        XCTAssertEqual(sleep.asleepDurationSeconds, 26000)
        XCTAssertEqual(sleep.coreDurationSeconds, 15000)
        XCTAssertEqual(sleep.deepDurationSeconds, 6000)
        XCTAssertEqual(sleep.remDurationSeconds, 5000)
        
        // Mindful minutes
        provider.mindfulMinutesResult = MindfulMinutesData(minutes: 20.0)
        let mindful = try await provider.fetchMindfulMinutes(start: now, end: now)
        XCTAssertEqual(mindful.minutes, 20.0)
        
        // Daylight time
        provider.daylightTimeResult = DaylightTimeData(durationSeconds: 1800.0)
        let daylight = try await provider.fetchTimeInDaylight(start: now, end: now)
        XCTAssertEqual(daylight.durationSeconds, 1800.0)
    }
    
    // MARK: - Real Provider Test Environment Safety Tests
    
    func testRealProviderSafetyInTestEnvironment() async throws {
        let provider = HealthKitDataProvider()
        let now = Date()
        
        // Real provider must gracefully return fallback/default values under tests
        let authorized = try await provider.requestAuthorization()
        XCTAssertTrue(authorized)
        
        let steps = try await provider.fetchDailySteps(on: now)
        XCTAssertEqual(steps.count, 0)
        
        let distance = try await provider.fetchDailyDistance(on: now)
        XCTAssertEqual(distance.meters, 0)
        
        let energy = try await provider.fetchDailyActiveEnergy(on: now)
        XCTAssertEqual(energy.kilocalories, 0)
        
        let hr = try await provider.fetchHeartRate(start: now, end: now)
        XCTAssertEqual(hr.bpm, 0)
        
        let hrv = try await provider.fetchHRV(start: now, end: now)
        XCTAssertEqual(hrv.sdnnMilliseconds, 0)
        
        let sleep = try await provider.fetchSleep(start: now, end: now)
        XCTAssertEqual(sleep.asleepDurationSeconds, 0)
        XCTAssertNil(sleep.coreDurationSeconds)
        XCTAssertNil(sleep.deepDurationSeconds)
        XCTAssertNil(sleep.remDurationSeconds)
        
        let mindful = try await provider.fetchMindfulMinutes(start: now, end: now)
        XCTAssertEqual(mindful.minutes, 0)
        
        let daylight = try await provider.fetchTimeInDaylight(start: now, end: now)
        XCTAssertEqual(daylight.durationSeconds, 0)
    }
    
    // MARK: - Codable Roundtrip Tests
    
    func testCodableRoundtrips() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // StepsData
        let steps = StepsData(count: 1000)
        let stepsData = try encoder.encode(steps)
        let decodedSteps = try decoder.decode(StepsData.self, from: stepsData)
        XCTAssertEqual(decodedSteps, steps)
        
        // DistanceData
        let distance = DistanceData(meters: 1200)
        let distanceData = try encoder.encode(distance)
        let decodedDistance = try decoder.decode(DistanceData.self, from: distanceData)
        XCTAssertEqual(decodedDistance, distance)
        
        // ActiveEnergyData
        let energy = ActiveEnergyData(kilocalories: 45)
        let energyData = try encoder.encode(energy)
        let decodedEnergy = try decoder.decode(ActiveEnergyData.self, from: energyData)
        XCTAssertEqual(decodedEnergy, energy)
        
        // HeartRateData
        let hr = HeartRateData(bpm: 72)
        let hrData = try encoder.encode(hr)
        let decodedHR = try decoder.decode(HeartRateData.self, from: hrData)
        XCTAssertEqual(decodedHR, hr)
        
        // HRVData
        let hrv = HRVData(sdnnMilliseconds: 50)
        let hrvData = try encoder.encode(hrv)
        let decodedHRV = try decoder.decode(HRVData.self, from: hrvData)
        XCTAssertEqual(decodedHRV, hrv)
        
        // SleepData
        let sleep = SleepData(
            asleepDurationSeconds: 3600 * 7,
            coreDurationSeconds: 3600 * 4,
            deepDurationSeconds: 3600 * 1.5,
            remDurationSeconds: 3600 * 1.5
        )
        let sleepData = try encoder.encode(sleep)
        let decodedSleep = try decoder.decode(SleepData.self, from: sleepData)
        XCTAssertEqual(decodedSleep, sleep)
        
        // MindfulMinutesData
        let mindful = MindfulMinutesData(minutes: 10)
        let mindfulData = try encoder.encode(mindful)
        let decodedMindful = try decoder.decode(MindfulMinutesData.self, from: mindfulData)
        XCTAssertEqual(decodedMindful, mindful)
        
        // DaylightTimeData
        let daylight = DaylightTimeData(durationSeconds: 300)
        let daylightData = try encoder.encode(daylight)
        let decodedDaylight = try decoder.decode(DaylightTimeData.self, from: daylightData)
        XCTAssertEqual(decodedDaylight, daylight)
    }
}
