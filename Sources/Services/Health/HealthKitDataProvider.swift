import Foundation

#if canImport(HealthKit)
import HealthKit

/// Real implementation of HealthDataProvider backed by HealthKit's HKHealthStore.
public final class HealthKitDataProvider: HealthDataProvider, @unchecked Sendable {
    private let store: HKHealthStore?
    
    public init() {
        let isTesting = CommandLine.arguments.contains { $0.contains("xctest") || $0.contains("swift-test") }
        if isTesting {
            self.store = nil
        } else {
            self.store = HKHealthStore()
        }
    }
    
    private var isTesting: Bool {
        return store == nil || CommandLine.arguments.contains { $0.contains("xctest") || $0.contains("swift-test") }
    }
    
    public func requestAuthorization() async throws -> Bool {
        if isTesting {
            return true
        }
        
        guard let store = store else { return false }
        
        var types: Set<HKObjectType> = []
        
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        if let hr = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(hr)
        }
        if let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        if #available(iOS 17.0, macOS 14.0, *) {
            if let daylight = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) {
                types.insert(daylight)
            }
        }
        
        guard !types.isEmpty else { return false }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            store.requestAuthorization(toShare: nil, read: types) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    public func fetchDailySteps(on date: Date) async throws -> StepsData {
        if isTesting {
            return StepsData(count: 0)
        }
        
        guard let _ = store,
              let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return StepsData(count: 0)
        }
        
        let (start, end) = dailyRange(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let sum = try await fetchSum(type: type, predicate: predicate, unit: .count())
        return StepsData(count: sum)
    }
    
    public func fetchDailyDistance(on date: Date) async throws -> DistanceData {
        if isTesting {
            return DistanceData(meters: 0)
        }
        
        guard let _ = store,
              let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return DistanceData(meters: 0)
        }
        
        let (start, end) = dailyRange(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let sum = try await fetchSum(type: type, predicate: predicate, unit: .meter())
        return DistanceData(meters: sum)
    }
    
    public func fetchDailyActiveEnergy(on date: Date) async throws -> ActiveEnergyData {
        if isTesting {
            return ActiveEnergyData(kilocalories: 0)
        }
        
        guard let _ = store,
              let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return ActiveEnergyData(kilocalories: 0)
        }
        
        let (start, end) = dailyRange(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let sum = try await fetchSum(type: type, predicate: predicate, unit: .kilocalorie())
        return ActiveEnergyData(kilocalories: sum)
    }
    
    public func fetchHeartRate(start: Date, end: Date) async throws -> HeartRateData {
        if isTesting {
            return HeartRateData(bpm: 0)
        }
        
        guard let store = store,
              let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return HeartRateData(bpm: 0)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let average = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let avgValue = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0.0
                continuation.resume(returning: avgValue)
            }
            store.execute(query)
        }
        return HeartRateData(bpm: average)
    }
    
    public func fetchHRV(start: Date, end: Date) async throws -> HRVData {
        if isTesting {
            return HRVData(sdnnMilliseconds: 0)
        }
        
        guard let store = store,
              let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return HRVData(sdnnMilliseconds: 0)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let average = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let avgValue = statistics?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli)) ?? 0.0
                continuation.resume(returning: avgValue)
            }
            store.execute(query)
        }
        return HRVData(sdnnMilliseconds: average)
    }
    
    public func fetchSleep(start: Date, end: Date) async throws -> SleepData {
        if isTesting {
            return SleepData(asleepDurationSeconds: 0)
        }
        
        guard let store = store,
              let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return SleepData(asleepDurationSeconds: 0)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SleepData, Error>) in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: SleepData(asleepDurationSeconds: 0))
                    return
                }
                
                var asleep: TimeInterval = 0
                var core: TimeInterval = 0
                var deep: TimeInterval = 0
                var rem: TimeInterval = 0
                
                for sample in categorySamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        asleep += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        asleep += duration
                        core += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        asleep += duration
                        deep += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        asleep += duration
                        rem += duration
                    default:
                        // Support deprecated asleep case raw value mapping if stored state uses it
                        if sample.value == 0 {
                            asleep += duration
                        }
                    }
                }
                
                continuation.resume(returning: SleepData(
                    asleepDurationSeconds: asleep,
                    coreDurationSeconds: core > 0 ? core : nil,
                    deepDurationSeconds: deep > 0 ? deep : nil,
                    remDurationSeconds: rem > 0 ? rem : nil
                ))
            }
            store.execute(query)
        }
    }
    
    public func fetchMindfulMinutes(start: Date, end: Date) async throws -> MindfulMinutesData {
        if isTesting {
            return MindfulMinutesData(minutes: 0)
        }
        
        guard let store = store,
              let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return MindfulMinutesData(minutes: 0)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let totalMinutes = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let duration = categorySamples.reduce(0.0) { sum, sample in
                    sum + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: duration / 60.0)
            }
            store.execute(query)
        }
        return MindfulMinutesData(minutes: totalMinutes)
    }
    
    public func fetchTimeInDaylight(start: Date, end: Date) async throws -> DaylightTimeData {
        if isTesting {
            return DaylightTimeData(durationSeconds: 0)
        }
        
        guard store != nil else {
            return DaylightTimeData(durationSeconds: 0)
        }
        
        if #available(iOS 17.0, macOS 14.0, *) {
            guard let type = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
                return DaylightTimeData(durationSeconds: 0)
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let sum = try await fetchSum(type: type, predicate: predicate, unit: .second())
            return DaylightTimeData(durationSeconds: sum)
        } else {
            return DaylightTimeData(durationSeconds: 0)
        }
    }
    
    // MARK: - Private Helpers
    
    private func dailyRange(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? date
        return (start, end)
    }
    
    private func fetchSum(type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async throws -> Double {
        guard let store = store else { return 0.0 }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let sumValue = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
                continuation.resume(returning: sumValue)
            }
            store.execute(query)
        }
    }
}

#else

/// Fallback implementation of HealthDataProvider when HealthKit is not available (e.g. macOS test runner).
public final class HealthKitDataProvider: HealthDataProvider {
    public init() {}
    
    public func requestAuthorization() async throws -> Bool {
        return true
    }
    
    public func fetchDailySteps(on date: Date) async throws -> StepsData {
        return StepsData(count: 0)
    }
    
    public func fetchDailyDistance(on date: Date) async throws -> DistanceData {
        return DistanceData(meters: 0)
    }
    
    public func fetchDailyActiveEnergy(on date: Date) async throws -> ActiveEnergyData {
        return ActiveEnergyData(kilocalories: 0)
    }
    
    public func fetchHeartRate(start: Date, end: Date) async throws -> HeartRateData {
        return HeartRateData(bpm: 0)
    }
    
    public func fetchHRV(start: Date, end: Date) async throws -> HRVData {
        return HRVData(sdnnMilliseconds: 0)
    }
    
    public func fetchSleep(start: Date, end: Date) async throws -> SleepData {
        return SleepData(asleepDurationSeconds: 0)
    }
    
    public func fetchMindfulMinutes(start: Date, end: Date) async throws -> MindfulMinutesData {
        return MindfulMinutesData(minutes: 0)
    }
    
    public func fetchTimeInDaylight(start: Date, end: Date) async throws -> DaylightTimeData {
        return DaylightTimeData(durationSeconds: 0)
    }
}

#endif
