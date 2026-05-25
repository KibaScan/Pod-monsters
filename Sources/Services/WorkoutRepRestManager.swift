import Foundation

public enum WorkoutState {
    case activeSet
    case restCapture
    case idle
}

@MainActor
public class WorkoutRepRestManager: ObservableObject {
    @Published public var currentState: WorkoutState = .idle
    @Published public var currentRepCount: Int = 0
    @Published public var shieldDurability: Double = 100.0
    @Published public var setDuration: Double = 0.0
    @Published public var restDuration: Double = 0.0
    
    public var shieldCrackedCallback: (() -> Void)?
    private var lastRepTime: Date = Date.distantPast
    
    public init() {}
    
    // MARK: - Public Interface Methods
    
    public func startWorkout() {
        self._startWorkout()
    }
    
    public func performRep(quality: Double) {
        performRep(quality: quality, duration: 2.0, at: Date())
    }
    
    public func performRep(quality: Double, duration: Double) {
        performRep(quality: quality, duration: duration, at: Date())
    }
    
    public func performRep(quality: Double, duration: Double, at timestamp: Date) {
        let shouldFireCallback = self._performRep(quality: quality, duration: duration, at: timestamp)
        if shouldFireCallback {
            self.shieldCrackedCallback?()
        }
    }
    
    public func startRestPeriod() {
        self._startRestPeriod()
    }
    
    public func tickSetDuration(_ seconds: Double) {
        self._tickSetDuration(seconds)
    }
    
    public func tickRestDuration(_ seconds: Double) {
        self._tickRestDuration(seconds)
    }
    
    public func bridgeHealthKitState(_ hkState: String) {
        self._bridgeHealthKitState(hkState)
    }
    
    // MARK: - Private Lock-Free Helper Methods
    
    private func _startWorkout() {
        currentState = .activeSet
        currentRepCount = 0
        shieldDurability = 100.0
        setDuration = 0.0
        restDuration = 0.0
        lastRepTime = Date.distantPast
    }
    
    private func _startRestPeriod() {
        currentState = .restCapture
        restDuration = 0.0
    }
    
    private func _performRep(quality: Double, duration: Double, at timestamp: Date) -> Bool {
        guard currentState == .activeSet else { return false }
        guard duration > 0.0 else { return false }
        
        // Clamp quality parameter to [0.0, 1.0]
        let clampedQuality: Double
        if quality.isNaN {
            clampedQuality = .nan
        } else {
            clampedQuality = max(0.0, min(1.0, quality))
        }
        
        // Reject reps with future timestamps (> 1.0s in the future)
        let now = Date()
        if timestamp.timeIntervalSince(now) > 1.0 {
            return false
        }
        
        // Reject reps with out-of-order timestamps
        if timestamp <= lastRepTime {
            return false
        }
        
        // De-duplication check: ignore reps that occur too close together (< 0.5s)
        if timestamp.timeIntervalSince(lastRepTime) < 0.5 {
            return false
        }
        
        lastRepTime = timestamp
        currentRepCount += 1
        
        let reduction = clampedQuality * 20.0
        let newDurability = shieldDurability - reduction
        
        var shouldFireCallback = false
        if newDurability <= 0.0 {
            let wasAlreadyCracked = (shieldDurability == 0.0)
            shieldDurability = 0.0
            if !wasAlreadyCracked {
                shouldFireCallback = true
            }
            _startRestPeriod()
        } else {
            shieldDurability = newDurability
        }
        
        return shouldFireCallback
    }
    
    private func _tickSetDuration(_ seconds: Double) {
        guard currentState == .activeSet else { return }
        setDuration += seconds
        if setDuration >= 120.0 {
            _startRestPeriod()
        }
    }
    
    private func _tickRestDuration(_ seconds: Double) {
        guard currentState == .restCapture else { return }
        restDuration += seconds
        if restDuration >= 90.0 {
            currentState = .idle
        }
    }
    
    private func _bridgeHealthKitState(_ hkState: String) {
        switch hkState.lowercased() {
        case "running":
            _startWorkout()
        case "paused":
            _startRestPeriod()
        case "ended":
            currentState = .idle
        default:
            break
        }
    }
}

@MainActor
public class MockHealthKitWorkoutBridge {
    public weak var manager: WorkoutRepRestManager?
    
    public init(manager: WorkoutRepRestManager) {
        self.manager = manager
    }
    
    public func simulateWorkoutStart() {
        manager?.bridgeHealthKitState("running")
    }
    
    public func simulateWorkoutPause() {
        manager?.bridgeHealthKitState("paused")
    }
    
    public func simulateWorkoutEnd() {
        manager?.bridgeHealthKitState("ended")
    }
}

