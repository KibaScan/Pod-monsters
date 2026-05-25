import Foundation
import CryptoKit

public enum BaitError: Error, Equatable {
    case emptyBait
    case subscriptionRequired
    case inventoryCapExceeded
    case invalidBaitType
}

public enum SessionError: Error, Equatable {
    case activeWorkoutConflict
    case noBuddyEquipped
    case monsterNotFound
}

public enum SerializationError: Error, Equatable {
    case signatureMissing
    case signatureMismatch
}

public protocol GameSessionDelegate: AnyObject {
    func gameSession(_ session: GameSession, didEvolveMonster monster: Monster, from oldMonster: Monster)
}

public struct GameSessionState: Codable {
    public let equippedBuddy: Monster?
    public let baitInventory: [BaitType: Int]
    public let capturedMonsters: [Monster]
    public let isSubscriber: Bool
}

@MainActor
public class GameSession: ObservableObject, AirPodsMotionManagerDelegate {
    @Published public var motionManager: AirPodsMotionManager
    @Published public var biomeScanner: BiomeScanner
    @Published public var fishingEngine: FishingEngine
    @Published public var workoutManager: WorkoutRepRestManager
    
    @Published public var equippedBuddy: Monster?
    @Published public var baitInventory: [BaitType: Int] = [:]
    @Published public var capturedMonsters: [Monster] = []
    @Published public var isSubscriber: Bool = false
    
    public weak var delegate: GameSessionDelegate?
    public var lastSavedState: GameSessionState?
    public var customPersistenceURL: URL?
    public static var disableAutoLoadOnTesting: Bool = true
    public static var testPersistenceURLOverride: URL?
    
    public var persistenceURL: URL {
        if let custom = customPersistenceURL {
            return custom
        }
        if let staticOverride = GameSession.testPersistenceURLOverride {
            return staticOverride
        }
        let isTesting = NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if isTesting {
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            return tempDir.appendingPathComponent("session_test.json")
        } else {
            let fileManager = FileManager.default
            let appSupportURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            let appSupportURL = appSupportURLs.first ?? fileManager.temporaryDirectory
            let podMonstersURL = appSupportURL.appendingPathComponent("PodMonsters", isDirectory: true)
            return podMonstersURL.appendingPathComponent("session.json")
        }
    }
    
    public var signatureURL: URL {
        return persistenceURL.deletingPathExtension().appendingPathExtension("json.sha256")
    }
    
    public init(motionManager: AirPodsMotionManager? = nil,
                biomeScanner: BiomeScanner? = nil,
                fishingEngine: FishingEngine? = nil,
                workoutManager: WorkoutRepRestManager? = nil) {
        self.motionManager = motionManager ?? AirPodsMotionManager()
        self.biomeScanner = biomeScanner ?? BiomeScanner()
        self.fishingEngine = fishingEngine ?? FishingEngine()
        self.workoutManager = workoutManager ?? WorkoutRepRestManager()
        
        // Bind delegate
        self.motionManager.delegate = self
        
        // Setup initial bait inventories
        baitInventory[.ironHooks] = 5
        baitInventory[.spinnerLures] = 5
        baitInventory[.mindBeads] = 5
        baitInventory[.masterLures] = 0
        
        // Setup fishing callbacks
        self.fishingEngine.captureSuccessCallback = { [weak self] monster in
            guard let self = self else { return }
            self.capturedMonsters.append(monster)
            if let faction = self.equippedBuddy?.faction {
                self.addXPToBuddy(GameConstants.captureSuccessXP, activityType: faction)
            }
        }
        
        // Restore state (cold launch)
        let isTesting = NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isTesting || !GameSession.disableAutoLoadOnTesting {
            do {
                try self.loadFromFile()
            } catch {
                print("Failed to restore state on cold launch: \(error)")
            }
        }
    }
    
    // MARK: - AirPodsMotionManagerDelegate
    public func motionManager(_ manager: AirPodsMotionManager, didUpdateCalibrationDelta yawDelta: Double, pitchDelta: Double) {
        // Keeps that method functional for calibration delta updates (without XP dripping)
    }
    
    public func motionManager(_ manager: AirPodsMotionManager, didUpdateHeadCarriage pitchAngleFromGravity: Double) {
        guard self.equippedBuddy != nil else { return }
        
        let pitchErr = abs(pitchAngleFromGravity)
        if pitchErr < GameConstants.postureGoodAngle {
            // Good posture drips postureGoodXP Kinetic XP
            self.addXPToBuddy(GameConstants.postureGoodXP, activityType: .kinetic)
        } else if pitchErr >= GameConstants.postureExtremeAngle {
            // Extreme deviation halts XP drip completely (do nothing)
        } else {
            // Intermediate deviation drips degraded XP
            self.addXPToBuddy(GameConstants.postureDegradedXP, activityType: .kinetic)
        }
    }
    
    public func motionManager(_ manager: AirPodsMotionManager, didUpdateStillnessScore score: Double) {
        self.fishingEngine.updateParasympatheticData(hrv: self.fishingEngine.hrvScore, stillness: score)
        self.fishingEngine.currentBiome = self.biomeScanner.currentState?.type ?? .neutral
    }
    
    private func addXPToBuddy(_ amount: Double, activityType: Faction) {
        guard var buddy = equippedBuddy else { return }
        let oldBuddy = buddy
        buddy.addXP(amount, activityType: activityType)
        equippedBuddy = buddy
        
        if let evolved = buddy.checkEvolution() {
            equippedBuddy = evolved
            // Persist changes
            try? saveToFile()
            // Trigger delegate/notification event
            delegate?.gameSession(self, didEvolveMonster: evolved, from: oldBuddy)
            NotificationCenter.default.post(
                name: .monsterDidEvolve,
                object: self,
                userInfo: ["monster": evolved, "oldMonster": oldBuddy]
            )
        }
    }
    
    // MARK: - Bait Economy & Budgets
    public func addBait(_ bait: BaitType, count: Int = 1) throws {
        // Validate bait type
        guard BaitType.allCases.contains(bait) else {
            throw BaitError.invalidBaitType
        }
        
        let current = self.baitInventory[bait, default: 0]
        let newCount = current + count
        
        // Bait inventory cap
        if newCount > 99 {
            self.baitInventory[bait] = 99
            throw BaitError.inventoryCapExceeded
        } else {
            self.baitInventory[bait] = newCount
        }
    }
    
    public func useBait(_ bait: BaitType) throws {
        // Validate bait type
        guard BaitType.allCases.contains(bait) else {
            throw BaitError.invalidBaitType
        }
        
        // Check subscriber constraints for Master Lures
        if bait == .masterLures && !self.isSubscriber {
            throw BaitError.subscriptionRequired
        }
        
        let current = self.baitInventory[bait, default: 0]
        if current <= 0 {
            throw BaitError.emptyBait
        }
        
        self.baitInventory[bait] = current - 1
    }
    
    // MARK: - Workout integration
    public func performWorkoutRep(quality: Double, duration: Double = 2.0) {
        self.workoutManager.performRep(quality: quality, duration: duration)
        if self.workoutManager.currentState == .activeSet && duration > 0 {
            self.addXPToBuddy(10.0 * quality, activityType: .forge)
        }
    }
    
    // MARK: - Fishing Integration
    public func castFishingLine(bait: BaitType) throws {
        // Dual Active Workouts check: Block if in active set
        if self.workoutManager.currentState == .activeSet {
            throw SessionError.activeWorkoutConflict
        }
        
        // Attempt to consume bait
        try self.useBait(bait)
        
        self.fishingEngine.castLine(bait: bait)
    }
    
    public func releaseBuddy(_ monster: Monster) throws {
        guard var buddy = self.equippedBuddy else {
            throw SessionError.noBuddyEquipped
        }
        
        guard let index = self.capturedMonsters.firstIndex(where: { $0.id == monster.id }) else {
            throw SessionError.monsterNotFound
        }
        
        self.capturedMonsters.remove(at: index)
        
        // Channel essence: Add huge XP matching the buddy's faction
        self.addXPToBuddy(GameConstants.releaseBuddyXP, activityType: buddy.faction)
    }
    
    // MARK: - State Serialization
    public func saveState() -> Data {
        do {
            try self.saveToFile()
            if let last = self.lastSavedState {
                return try JSONEncoder().encode(last)
            }
        } catch {
            print("Failed to save state: \(error)")
        }
        return Data()
    }
    
    public func saveToFile() throws {
        let state = GameSessionState(
            equippedBuddy: self.equippedBuddy,
            baitInventory: self.baitInventory,
            capturedMonsters: self.capturedMonsters,
            isSubscriber: self.isSubscriber
        )
        self.lastSavedState = state
        
        let data = try JSONEncoder().encode(state)
        let url = self.persistenceURL
        let parentDir = url.deletingLastPathComponent()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
        }
        try data.write(to: url, options: .atomic)
        
        // Write SHA-256 signature
        let hash = SHA256.hash(data: data)
        let signature = hash.compactMap { String(format: "%02x", $0) }.joined()
        let sigUrl = self.signatureURL
        try Data(signature.utf8).write(to: sigUrl, options: .atomic)
    }
    
    public func loadFromFile() throws {
        let url = self.persistenceURL
        let sigUrl = self.signatureURL
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        
        guard fileManager.fileExists(atPath: sigUrl.path) else {
            throw SerializationError.signatureMissing
        }
        
        let data = try Data(contentsOf: url)
        let sigData = try Data(contentsOf: sigUrl)
        guard let sigString = String(data: sigData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw SerializationError.signatureMissing
        }
        
        // Generate current SHA-256
        let hash = SHA256.hash(data: data)
        let expectedSig = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        guard sigString.lowercased() == expectedSig.lowercased() else {
            throw SerializationError.signatureMismatch
        }
        
        try self.restoreState(from: data)
    }
    
    public func restoreState(from data: Data) throws {
        let state = try JSONDecoder().decode(GameSessionState.self, from: data)
        self.equippedBuddy = state.equippedBuddy
        self.baitInventory = state.baitInventory
        self.capturedMonsters = state.capturedMonsters
        self.isSubscriber = state.isSubscriber
        self.lastSavedState = state
    }
    
    public func appDidEnterBackground() {
        _ = self.saveState()
    }
    
    public func appWillEnterForeground() {
        do {
            try self.loadFromFile()
        } catch {
            print("Failed to reload from file on foreground: \(error)")
        }
        if let last = self.lastSavedState {
            self.equippedBuddy = last.equippedBuddy
            self.baitInventory = last.baitInventory
            self.capturedMonsters = last.capturedMonsters
            self.isSubscriber = last.isSubscriber
        }
    }
}

extension Notification.Name {
    public static let monsterDidEvolve = Notification.Name("monsterDidEvolve")
}
