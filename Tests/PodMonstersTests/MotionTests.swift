import XCTest
import CoreMotion
@testable import PodMonsters

class MockMotionDelegate: AirPodsMotionManagerDelegate {
    var lastYaw: Double = -999.0
    var lastPitch: Double = -999.0
    var lastStillnessScore: Double = -999.0
    var lastCarriagePitch: Double = -999.0
    var carriagePitchCount: Int = 0
    
    var onCalibrationUpdate: (() -> Void)?
    var onStillnessUpdate: (() -> Void)?
    var onCarriageUpdate: (() -> Void)?
    
    func motionManager(_ manager: AirPodsMotionManager, didUpdateCalibrationDelta yawDelta: Double, pitchDelta: Double) {
        lastYaw = yawDelta
        lastPitch = pitchDelta
        onCalibrationUpdate?()
    }
    
    func motionManager(_ manager: AirPodsMotionManager, didUpdateStillnessScore score: Double) {
        lastStillnessScore = score
        onStillnessUpdate?()
    }
    
    func motionManager(_ manager: AirPodsMotionManager, didUpdateHeadCarriage pitchAngleFromGravity: Double) {
        lastCarriagePitch = pitchAngleFromGravity
        carriagePitchCount += 1
        onCarriageUpdate?()
    }
}

class TestHeadphoneMotionManager: HeadphoneMotionProvider {
    var isAvailableOverride: Bool = true
    var isActiveOverride: Bool = false
    var registeredQueue: OperationQueue?
    var registeredHandler: CMHeadphoneMotionManager.DeviceMotionHandler?
    
    var isDeviceMotionAvailable: Bool {
        return isAvailableOverride
    }
    
    var isDeviceMotionActive: Bool {
        return isActiveOverride
    }
    
    func startDeviceMotionUpdates(to queue: OperationQueue, withHandler handler: @escaping CMHeadphoneMotionManager.DeviceMotionHandler) {
        isActiveOverride = true
        registeredQueue = queue
        registeredHandler = handler
    }
    
    func stopDeviceMotionUpdates() {
        isActiveOverride = false
        registeredQueue = nil
        registeredHandler = nil
    }
}

@MainActor
final class MotionTests: XCTestCase {
    
    func testT1_F3_01_ServiceStartStop() {
        let manager = AirPodsMotionManager()
        XCTAssertFalse(manager.isTracking)
        
        manager.startTracking()
        XCTAssertTrue(manager.isTracking)
        
        manager.stopTracking()
        XCTAssertFalse(manager.isTracking)
    }
    
    func testT1_F3_02_CalibrateReferenceAngle() {
        let manager = AirPodsMotionManager()
        let delegate = MockMotionDelegate()
        manager.delegate = delegate
        
        manager.startTracking()
        manager.simulateHeadMovement(yaw: 45.0, pitch: -30.0)
        XCTAssertEqual(manager.calibrationDelta.yaw, 45.0)
        
        manager.calibrateReferenceAngle()
        XCTAssertEqual(manager.calibrationDelta.yaw, 0.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 0.0)
        XCTAssertEqual(delegate.lastYaw, 0.0)
        XCTAssertEqual(delegate.lastPitch, 0.0)
    }
    
    func testT1_F3_03_HeadOrientationMath() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // Input yaw/pitch delta and verify correct capture
        manager.simulateHeadMovement(yaw: 15.0, pitch: 10.0)
        XCTAssertEqual(manager.calibrationDelta.yaw, 15.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 10.0)
    }
    
    func testT1_F3_04_StillnessScoreUpdate() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // Feed micro-movements of 0.2 magnitude -> stillness is 1 - 0.2 = 0.8
        manager.feedMicroMovements(magnitude: 0.2)
        XCTAssertEqual(manager.stillnessScore, 0.8)
        
        // Exceed range: magnitude 1.5 -> stillness 0.0
        manager.feedMicroMovements(magnitude: 1.5)
        XCTAssertEqual(manager.stillnessScore, 0.0)
    }
    
    func testT1_F3_05_HeadGestureVerification() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        let expectation = self.expectation(description: "Gesture detection")
        manager.onGestureDetected = { gesture in
            XCTAssertEqual(gesture, "pinch-and-flick")
            expectation.fulfill()
        }
        
        manager.simulateGesture("pinch-and-flick")
        waitForExpectations(timeout: 1.0)
    }
    
    func testT2_F3_01_ExtremeDeviationAngles() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // Simulate extreme wrapping: 450 degrees should wrap to 90 degrees
        manager.simulateHeadMovement(yaw: 450.0, pitch: -390.0)
        XCTAssertEqual(manager.calibrationDelta.yaw, 90.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, -30.0)
        
        // Negative wrapping: -400 degrees should wrap to -40 degrees
        manager.simulateHeadMovement(yaw: -400.0, pitch: 0.0)
        XCTAssertEqual(manager.calibrationDelta.yaw, -40.0)
    }
    
    func testT2_F3_02_ExactStillnessThreshold() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // Exact boundary (0.5 magnitude)
        manager.feedMicroMovements(magnitude: 0.5)
        XCTAssertEqual(manager.stillnessScore, 0.5)
        
        // Extreme boundary (0.0 magnitude -> 1.0 score)
        manager.feedMicroMovements(magnitude: 0.0)
        XCTAssertEqual(manager.stillnessScore, 1.0)
        
        // Extreme boundary (1.0 magnitude -> 0.0 score)
        manager.feedMicroMovements(magnitude: 1.0)
        XCTAssertEqual(manager.stillnessScore, 0.0)
    }
    
    func testT2_F3_03_RapidCalibrationReset() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // Toggle rapidly and verify it stabilizes at 0.0
        for _ in 0..<50 {
            manager.calibrateReferenceAngle()
        }
        XCTAssertEqual(manager.calibrationDelta.yaw, 0.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 0.0)
    }
    
    func testT2_F3_04_NoSignalFallback() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        XCTAssertTrue(manager.isTracking)
        
        manager.simulateConnectionLoss()
        XCTAssertFalse(manager.isTracking)
        XCTAssertFalse(manager.isConnected)
        
        // Attempt tracking while offline should fail
        manager.startTracking()
        XCTAssertFalse(manager.isTracking)
    }
    
    func testT2_F3_05_FloatingPrecisionLimits() {
        let manager = AirPodsMotionManager()
        manager.startTracking()
        
        // Precision micro-movements on scale of 1e-7
        let microMag = 1e-7
        manager.feedMicroMovements(magnitude: microMag)
        XCTAssertEqual(manager.stillnessScore, 1.0 - microMag)
    }
    
    func testT3_F3_01_RealWrappingAndStartStop() {
        let manager = AirPodsMotionManager()
        let mockHeadphone = TestHeadphoneMotionManager()
        manager.motionManagerInstance = mockHeadphone
        
        // 1. Verify initial state
        XCTAssertFalse(manager.isTracking)
        XCTAssertFalse(mockHeadphone.isDeviceMotionActive)
        
        // 2. Start tracking with manager available
        mockHeadphone.isAvailableOverride = true
        manager.startTracking()
        
        XCTAssertTrue(manager.isTracking)
        XCTAssertTrue(mockHeadphone.isDeviceMotionActive)
        XCTAssertNotNil(mockHeadphone.registeredHandler)
        
        // 3. Stop tracking
        manager.stopTracking()
        XCTAssertFalse(manager.isTracking)
        XCTAssertFalse(mockHeadphone.isDeviceMotionActive)
    }
    
    func testT3_F3_02_CalibrationMathDegreesAndRadians() {
        let manager = AirPodsMotionManager()
        let delegate = MockMotionDelegate()
        manager.delegate = delegate
        
        manager.startTracking()
        
        // Convert radians to degrees. Feed raw motion:
        // yaw = 0.5 * .pi radians -> 90.0 degrees
        // pitch = -0.25 * .pi radians -> -45.0 degrees
        let rot = CMRotationRate(x: 0, y: 0, z: 0)
        manager.processRawMotion(yawRad: 0.5 * .pi, pitchRad: -0.25 * .pi, rotationRate: rot)
        
        // Before calibration, reference is 0.0, so delta should be equal to the current values
        XCTAssertEqual(manager.calibrationDelta.yaw, 90.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, -45.0)
        XCTAssertEqual(delegate.lastYaw, 90.0)
        XCTAssertEqual(delegate.lastPitch, -45.0)
        
        // Calibrate
        manager.calibrateReferenceAngle()
        XCTAssertEqual(manager.calibrationDelta.yaw, 0.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 0.0)
        
        // Move again: yaw = 0.75 * .pi radians -> 135.0 degrees. Delta = 135 - 90 = 45 degrees
        manager.processRawMotion(yawRad: 0.75 * .pi, pitchRad: -0.25 * .pi, rotationRate: rot)
        XCTAssertEqual(manager.calibrationDelta.yaw, 45.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 0.0)
    }
    
    func testT3_F3_03_RealStillnessTracking() {
        let manager = AirPodsMotionManager()
        let delegate = MockMotionDelegate()
        manager.delegate = delegate
        
        manager.startTracking()
        
        // Feed micro-movements of rotation rate. 
        // Let's use rot = (x: 0.3, y: 0.4, z: 0.0) -> mag = sqrt(0.09 + 0.16) = 0.5
        // stillnessScore = 1.0 - 0.5 = 0.5
        let rot1 = CMRotationRate(x: 0.3, y: 0.4, z: 0.0)
        manager.processRawMotion(yawRad: 0, pitchRad: 0, rotationRate: rot1)
        XCTAssertEqual(manager.stillnessScore, 0.5)
        XCTAssertEqual(delegate.lastStillnessScore, 0.5)
        
        // Test extreme rotation: rot = (x: 1.5, y: 0, z: 0) -> mag = 1.5 -> score = 0.0 (bounded)
        let rot2 = CMRotationRate(x: 1.5, y: 0, z: 0)
        manager.processRawMotion(yawRad: 0, pitchRad: 0, rotationRate: rot2)
        XCTAssertEqual(manager.stillnessScore, 0.0)
        
        // Test NaN/infinite handling: rot = (x: .nan, y: 0, z: 0) -> should result in score = 1.0
        let rot3 = CMRotationRate(x: .nan, y: 0, z: 0)
        manager.processRawMotion(yawRad: 0, pitchRad: 0, rotationRate: rot3)
        XCTAssertEqual(manager.stillnessScore, 1.0)
    }
    
    func testT3_F3_04_SimulatorFallbackGraceful() {
        let manager = AirPodsMotionManager()
        let mockHeadphone = TestHeadphoneMotionManager()
        manager.motionManagerInstance = mockHeadphone
        
        // If CMHeadphoneMotionManager is not available
        mockHeadphone.isAvailableOverride = false
        
        // Start tracking should still succeed (falling back gracefully to simulator/mock mode)
        manager.startTracking()
        XCTAssertTrue(manager.isTracking)
        XCTAssertFalse(mockHeadphone.isDeviceMotionActive) // real motion not active
        
        // Simulated head movement and stillness should still be perfectly functional
        manager.simulateHeadMovement(yaw: 30.0, pitch: 20.0)
        XCTAssertEqual(manager.calibrationDelta.yaw, 30.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 20.0)
        
        manager.feedMicroMovements(magnitude: 0.1)
        XCTAssertEqual(manager.stillnessScore, 0.9)
    }
    
    func testT3_F3_05_HeadCarriageUpdateDelegation() {
        let manager = AirPodsMotionManager()
        let delegate = MockMotionDelegate()
        manager.delegate = delegate
        
        manager.startTracking()
        
        // 1. Verify processRawMotion triggers head carriage delegate update
        let rot = CMRotationRate(x: 0.0, y: 0.0, z: 0.0)
        // pitch = -0.25 * .pi radians -> -45.0 degrees
        manager.processRawMotion(yawRad: 0.0, pitchRad: -0.25 * .pi, rotationRate: rot)
        XCTAssertEqual(delegate.lastCarriagePitch, -45.0)
        XCTAssertEqual(delegate.carriagePitchCount, 1)
        
        // 2. Verify simulateHeadMovement triggers head carriage delegate update
        manager.simulateHeadMovement(yaw: 10.0, pitch: 15.0)
        XCTAssertEqual(delegate.lastCarriagePitch, 15.0)
        XCTAssertEqual(delegate.carriagePitchCount, 2)
    }
    
    func testNaNAndInfiniteMathSafeguards() {
        let manager = AirPodsMotionManager()
        let delegate = MockMotionDelegate()
        manager.delegate = delegate
        manager.startTracking()
        
        // Feed raw motion with NaN and Infinite values
        let rot = CMRotationRate(x: .nan, y: .infinity, z: -.infinity)
        manager.processRawMotion(yawRad: .nan, pitchRad: .infinity, rotationRate: rot)
        
        // It should use 0.0 or 1.0 (stillness) as safe default values instead of crashing or leaving properties as NaN/Infinity
        XCTAssertEqual(manager.calibrationDelta.yaw, 0.0)
        XCTAssertEqual(manager.calibrationDelta.pitch, 0.0)
        XCTAssertEqual(delegate.lastYaw, 0.0)
        XCTAssertEqual(delegate.lastPitch, 0.0)
        XCTAssertEqual(manager.stillnessScore, 1.0)
    }
}
