import Foundation

/// Protocol representing the contract for the HealthKit ingestion layer.
/// Surfacers all required signals in an async, Sendable, and test-injectable fashion.
public protocol HealthDataProvider: Sendable {
    
    /// Requests authorization from the user for accessing health data.
    /// - Returns: True if authorization succeeded or is granted, false otherwise.
    func requestAuthorization() async throws -> Bool
    
    /// Fetches steps count for a specific date.
    func fetchDailySteps(on date: Date) async throws -> StepsData
    
    /// Fetches walking/running distance in meters for a specific date.
    func fetchDailyDistance(on date: Date) async throws -> DistanceData
    
    /// Fetches active energy in kilocalories for a specific date.
    func fetchDailyActiveEnergy(on date: Date) async throws -> ActiveEnergyData
    
    /// Fetches average heart rate in BPM between two dates.
    func fetchHeartRate(start: Date, end: Date) async throws -> HeartRateData
    
    /// Fetches average HRV SDNN in milliseconds between two dates.
    func fetchHRV(start: Date, end: Date) async throws -> HRVData
    
    /// Fetches sleep session details between two dates.
    func fetchSleep(start: Date, end: Date) async throws -> SleepData
    
    /// Fetches total mindful minutes between two dates.
    func fetchMindfulMinutes(start: Date, end: Date) async throws -> MindfulMinutesData
    
    /// Fetches total daylight time in seconds between two dates.
    func fetchTimeInDaylight(start: Date, end: Date) async throws -> DaylightTimeData
}
