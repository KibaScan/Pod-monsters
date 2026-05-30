import Foundation

/// Injectable mock implementation of HealthDataProvider returning configurable values for tests.
public final class MockHealthDataProvider: HealthDataProvider, @unchecked Sendable {
    public var authorizationResult: Bool = true
    public var shouldFail: Bool = false
    public var errorToThrow: Error = NSError(domain: "MockHealthDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mocked fetch failure"])
    
    public var stepsResult = StepsData(count: 5000)
    public var distanceResult = DistanceData(meters: 3500)
    public var activeEnergyResult = ActiveEnergyData(kilocalories: 250)
    public var heartRateResult = HeartRateData(bpm: 72)
    public var hrvResult = HRVData(sdnnMilliseconds: 65)
    public var sleepResult = SleepData(asleepDurationSeconds: 28800, coreDurationSeconds: 18000, deepDurationSeconds: 7200, remDurationSeconds: 3600)
    public var mindfulMinutesResult = MindfulMinutesData(minutes: 15)
    public var daylightTimeResult = DaylightTimeData(durationSeconds: 1200)
    
    public init() {}
    
    public func requestAuthorization() async throws -> Bool {
        if shouldFail {
            throw errorToThrow
        }
        return authorizationResult
    }
    
    public func fetchDailySteps(on date: Date) async throws -> StepsData {
        if shouldFail {
            throw errorToThrow
        }
        return stepsResult
    }
    
    public func fetchDailyDistance(on date: Date) async throws -> DistanceData {
        if shouldFail {
            throw errorToThrow
        }
        return distanceResult
    }
    
    public func fetchDailyActiveEnergy(on date: Date) async throws -> ActiveEnergyData {
        if shouldFail {
            throw errorToThrow
        }
        return activeEnergyResult
    }
    
    public func fetchHeartRate(start: Date, end: Date) async throws -> HeartRateData {
        if shouldFail {
            throw errorToThrow
        }
        return heartRateResult
    }
    
    public func fetchHRV(start: Date, end: Date) async throws -> HRVData {
        if shouldFail {
            throw errorToThrow
        }
        return hrvResult
    }
    
    public func fetchSleep(start: Date, end: Date) async throws -> SleepData {
        if shouldFail {
            throw errorToThrow
        }
        return sleepResult
    }
    
    public func fetchMindfulMinutes(start: Date, end: Date) async throws -> MindfulMinutesData {
        if shouldFail {
            throw errorToThrow
        }
        return mindfulMinutesResult
    }
    
    public func fetchTimeInDaylight(start: Date, end: Date) async throws -> DaylightTimeData {
        if shouldFail {
            throw errorToThrow
        }
        return daylightTimeResult
    }
}
