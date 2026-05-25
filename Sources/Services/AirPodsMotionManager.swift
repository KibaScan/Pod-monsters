import Foundation
import CoreMotion

public protocol HeadphoneMotionProvider: AnyObject {
    var isDeviceMotionAvailable: Bool { get }
    var isDeviceMotionActive: Bool { get }
    func startDeviceMotionUpdates(to queue: OperationQueue, withHandler handler: @escaping CMHeadphoneMotionManager.DeviceMotionHandler)
    func stopDeviceMotionUpdates()
}

extension CMHeadphoneMotionManager: HeadphoneMotionProvider {}

@MainActor
public protocol AirPodsMotionManagerDelegate: AnyObject {
    func motionManager(_ manager: AirPodsMotionManager, didUpdateCalibrationDelta yawDelta: Double, pitchDelta: Double)
    func motionManager(_ manager: AirPodsMotionManager, didUpdateStillnessScore score: Double)
    func motionManager(_ manager: AirPodsMotionManager, didUpdateHeadCarriage pitchAngleFromGravity: Double)
}

@MainActor
public class AirPodsMotionManager: ObservableObject {
    @Published var isTracking: Bool = false
    @Published var calibrationDelta: (yaw: Double, pitch: Double) = (0.0, 0.0)
    @Published var stillnessScore: Double = 1.0 // 0.0 to 1.0
    @Published var isConnected: Bool = true
    @Published public var motionSampleInterval: TimeInterval = 0.1
    
    public weak var delegate: AirPodsMotionManagerDelegate?
    public var onGestureDetected: ((String) -> Void)?
    
    // CoreMotion tracking variables
    private var currentYaw: Double = 0.0
    private var currentPitch: Double = 0.0
    private var referenceYaw: Double = 0.0
    private var referencePitch: Double = 0.0
    private var lastProcessedTime: Date = Date.distantPast
    
    // Preview / Mock tracking variables
    private var baselineStillnessScore: Double = 1.0
    private var restoreStillnessTask: Task<Void, Never>?
    
    // Injectable headphone motion manager for unit testing
    internal var motionManagerInstance: HeadphoneMotionProvider?
    private var headphoneMotionManager: HeadphoneMotionProvider {
        if let instance = motionManagerInstance {
            return instance
        }
        #if DEBUG
        if NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1" {
            let mock = MockHeadphoneMotionManager()
            motionManagerInstance = mock
            return mock
        }
        #endif
        let manager = _defaultHeadphoneMotionManager ?? CMHeadphoneMotionManager()
        _defaultHeadphoneMotionManager = manager
        return manager
    }
    private var _defaultHeadphoneMotionManager: HeadphoneMotionProvider?
    
    public init() {}
    
    public func startTracking() {
        guard self.isConnected else { return }
        self.isTracking = true
        
        if self.headphoneMotionManager.isDeviceMotionAvailable {
            self.headphoneMotionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    guard self.isTracking && self.isConnected else { return }
                    if let error = error {
                        print("AirPodsMotionManager error receiving motion: \(error)")
                        return
                    }
                    if let motion = motion {
                        self.processDeviceMotion(motion)
                    }
                }
            }
        } else {
            print("CMHeadphoneMotionManager is not available. Continuing in fallback/simulator mode.")
        }
    }
    
    public func stopTracking() {
        self.isTracking = false
        self.restoreStillnessTask?.cancel()
        if self.headphoneMotionManager.isDeviceMotionActive {
            self.headphoneMotionManager.stopDeviceMotionUpdates()
        }
    }
    
    public func calibrateReferenceAngle() {
        self.referenceYaw = self.currentYaw
        self.referencePitch = self.currentPitch
        
        let yawDelta = self.wrapAngle(self.currentYaw - self.referenceYaw)
        let pitchDelta = self.wrapAngle(self.currentPitch - self.referencePitch)
        
        self.calibrationDelta = (yaw: yawDelta, pitch: pitchDelta)
        
        self.delegate?.motionManager(self, didUpdateCalibrationDelta: yawDelta, pitchDelta: pitchDelta)
    }
    
    private func wrapAngle(_ angle: Double) -> Double {
        // Handle NaN/Infinity
        guard !angle.isNaN && !angle.isInfinite else { return 0.0 }
        var wrapped = angle.truncatingRemainder(dividingBy: 360.0)
        if wrapped > 180.0 {
            wrapped -= 360.0
        } else if wrapped <= -180.0 {
            wrapped += 360.0
        }
        return wrapped
    }
    
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= motionSampleInterval else {
            return
        }
        lastProcessedTime = now
        
        processRawMotion(
            yawRad: motion.attitude.yaw,
            pitchRad: motion.attitude.pitch,
            rotationRate: motion.rotationRate
        )
    }
    
    internal func processRawMotion(yawRad: Double, pitchRad: Double, rotationRate: CMRotationRate) {
        guard self.isTracking && self.isConnected else { return }
        
        // Handle NaN/Infinity in inputs
        let safeYawRad = (yawRad.isNaN || yawRad.isInfinite) ? 0.0 : yawRad
        let safePitchRad = (pitchRad.isNaN || pitchRad.isInfinite) ? 0.0 : pitchRad
        
        // Convert attitude yaw and pitch from radians to degrees: degrees = radians * 180.0 / .pi
        let yawDeg = safeYawRad * 180.0 / .pi
        let pitchDeg = safePitchRad * 180.0 / .pi
        
        self.currentYaw = yawDeg
        self.currentPitch = pitchDeg
        
        self.delegate?.motionManager(self, didUpdateHeadCarriage: pitchDeg)
        
        let yawDelta = self.wrapAngle(self.currentYaw - self.referenceYaw)
        let pitchDelta = self.wrapAngle(self.currentPitch - self.referencePitch)
        
        // Estimate stillness magnitude from rotation rate: sqrt(x^2 + y^2 + z^2)
        let rot = rotationRate
        let safeX = (rot.x.isNaN || rot.x.isInfinite) ? 0.0 : rot.x
        let safeY = (rot.y.isNaN || rot.y.isInfinite) ? 0.0 : rot.y
        let safeZ = (rot.z.isNaN || rot.z.isInfinite) ? 0.0 : rot.z
        let mag = sqrt(safeX * safeX + safeY * safeY + safeZ * safeZ)
        
        let score: Double
        if mag.isNaN || mag.isInfinite {
            score = 1.0
        } else {
            score = max(0.0, min(1.0, 1.0 - mag))
        }
        
        self.calibrationDelta = (yaw: yawDelta, pitch: pitchDelta)
        self.stillnessScore = score
        
        self.delegate?.motionManager(self, didUpdateCalibrationDelta: yawDelta, pitchDelta: pitchDelta)
        self.delegate?.motionManager(self, didUpdateStillnessScore: score)
    }
    
    public func simulateHeadMovement(yaw: Double, pitch: Double) {
        guard self.isTracking && self.isConnected else { return }
        
        let wrappedYaw = self.wrapAngle(yaw)
        let wrappedPitch = self.wrapAngle(pitch)
        
        // Calculate a simulated motion delta from the previous orientation
        let yawDiff = self.wrapAngle(wrappedYaw - self.currentYaw)
        let pitchDiff = self.wrapAngle(wrappedPitch - self.currentPitch)
        let delta = sqrt(yawDiff * yawDiff + pitchDiff * pitchDiff)
        
        self.currentYaw = wrappedYaw
        self.currentPitch = wrappedPitch
        
        self.delegate?.motionManager(self, didUpdateHeadCarriage: wrappedPitch)
        
        let yawDelta = self.wrapAngle(self.currentYaw - self.referenceYaw)
        let pitchDelta = self.wrapAngle(self.currentPitch - self.referencePitch)
        
        self.calibrationDelta = (yaw: yawDelta, pitch: pitchDelta)
        
        self.delegate?.motionManager(self, didUpdateCalibrationDelta: yawDelta, pitchDelta: pitchDelta)
        
        // If there's non-trivial movement, temporarily degrade stillness score
        if delta > 0.01 {
            // scale rotation rate mapping (e.g. 30 degrees of sudden movement drops score to 0)
            let mockRotationRate = min(1.0, delta / 30.0)
            let score = max(0.0, min(1.0, 1.0 - mockRotationRate))
            
            // Stillness score drops immediately to reflect current motion
            self.stillnessScore = score
            self.delegate?.motionManager(self, didUpdateStillnessScore: score)
            
            // Debounce restoring the stillness score back to the baseline once motion stops
            self.restoreStillnessTask?.cancel()
            self.restoreStillnessTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    guard self.isTracking && self.isConnected else { return }
                    let finalScore = self.baselineStillnessScore
                    self.stillnessScore = finalScore
                    self.delegate?.motionManager(self, didUpdateStillnessScore: finalScore)
                }
            }
        }
    }
    
    public func feedMicroMovements(magnitude: Double) {
        guard self.isTracking && self.isConnected else { return }
        // numerical stability checks
        guard !magnitude.isNaN && !magnitude.isInfinite else { return }
        let score = max(0.0, min(1.0, 1.0 - magnitude))
        
        // Set both baseline and current score
        self.baselineStillnessScore = score
        self.stillnessScore = score
        self.delegate?.motionManager(self, didUpdateStillnessScore: score)
    }
    
    public func simulateGesture(_ gestureName: String) {
        guard self.isTracking && self.isConnected else { return }
        self.onGestureDetected?(gestureName)
    }
    
    public func simulateConnectionLoss() {
        self.isConnected = false
        self.isTracking = false
        if self.headphoneMotionManager.isDeviceMotionActive {
            self.headphoneMotionManager.stopDeviceMotionUpdates()
        }
    }
    
    public func simulateConnectionRestore() {
        self.isConnected = true
    }
}

#if DEBUG
class MockHeadphoneMotionManager: HeadphoneMotionProvider {
    private var _isDeviceMotionActive = false
    
    var isDeviceMotionAvailable: Bool {
        return false
    }
    
    var isDeviceMotionActive: Bool {
        return _isDeviceMotionActive
    }
    
    func startDeviceMotionUpdates(to queue: OperationQueue, withHandler handler: @escaping CMHeadphoneMotionManager.DeviceMotionHandler) {
        _isDeviceMotionActive = true
    }
    
    func stopDeviceMotionUpdates() {
        _isDeviceMotionActive = false
    }
}
#endif

