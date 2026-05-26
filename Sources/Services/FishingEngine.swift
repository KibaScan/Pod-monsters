import Foundation

public enum FishingState: String, Codable {
    case idle, casting, waiting, biting, reeling, captured, snapped
}

@MainActor
public class FishingEngine: ObservableObject {
    @Published public var currentState: FishingState = .idle
    @Published public var currentBiome: BiomeType = .neutral
    @Published public var lineTension: Double = 0.0 {
        didSet {
            if lineTension >= GameConstants.maxLineTension {
                if lineTension != GameConstants.maxLineTension {
                    lineTension = GameConstants.maxLineTension
                }
                if currentState != .snapped {
                    currentState = .snapped
                }
            } else if lineTension < GameConstants.minLineTension {
                if lineTension != GameConstants.minLineTension {
                    lineTension = GameConstants.minLineTension
                }
            }
        }
    }
    @Published public var breathPaceMatchScore: Double = 1.0 // 0.0 to 1.0
    
    @Published public var patienceLevel: Double = 1.0
    @Published public var hrvScore: Double = 60.0
    @Published public var stillnessScore: Double = 1.0
    @Published public var parasympatheticShiftConfirmed: Bool = false
    @Published public var sessionBaselineHRV: Double = 60.0
    
    public var hapticTugCallback: (() -> Void)?
    public var captureSuccessCallback: ((Monster) -> Void)?
    public var currentBait: BaitType?
    
    public init() {}
    
    public func castLine(bait: BaitType) {
        guard self.currentState == .idle else { return }
        self.sessionBaselineHRV = self.hrvScore
        self.currentBait = bait
        self.currentState = .casting
        self.patienceLevel = 1.0
    }
    
    public func triggerBite() {
        guard self.currentState == .waiting else { return }
        self.currentState = .biting
        self.hapticTugCallback?()
    }
    
    public func setHook() {
        guard self.currentState == .biting else { return }
        self.currentState = .reeling
        self.lineTension = GameConstants.hookSetTension
    }
    
    public func updateParasympatheticData(hrv: Double, stillness: Double) {
        self.hrvScore = hrv
        self.stillnessScore = stillness
        
        let passesGating = stillness > GameConstants.stillnessThreshold && hrv >= (self.sessionBaselineHRV - GameConstants.hrvTolerance)
        let previousConfirmed = self.parasympatheticShiftConfirmed
        
        if passesGating {
            self.parasympatheticShiftConfirmed = true
            if !previousConfirmed {
                self.patienceLevel = 1.0
            }
        } else {
            self.parasympatheticShiftConfirmed = false
        }
    }
    
    public func updateBreathingTempo(simulatedRate: Double) {
        guard !simulatedRate.isNaN && !simulatedRate.isInfinite else { return }
        
        // Ideal breathing rate is 6.0 breaths/min (4-7-8 rhythm)
        let diff = abs(simulatedRate - GameConstants.idealBreathingRate)
        let score = max(0.0, min(1.0, 1.0 - (diff / GameConstants.idealBreathingRate)))
        self.breathPaceMatchScore = score
        
        if self.currentState == .reeling {
            let stillnessFactor = self.stillnessScore >= GameConstants.stillnessThreshold ? 1.0 : self.stillnessScore
            if score > GameConstants.excellentBreathingThreshold {
                if stillnessFactor.isNaN {
                    self.lineTension = .nan
                } else {
                    self.lineTension = max(GameConstants.minLineTension, self.lineTension - GameConstants.tensionReductionMultiplier * stillnessFactor)
                }
            } else if score < GameConstants.poorBreathingThreshold {
                if self.stillnessScore.isNaN {
                    self.lineTension = .nan
                } else {
                    self.lineTension = min(GameConstants.maxLineTension, self.lineTension + GameConstants.tensionIncreaseMultiplier * (2.0 - self.stillnessScore))
                }
            }
        }
    }
    
    public func reelIn(biome: BiomeType? = nil) {
        guard self.currentState == .reeling else { return }
        
        let resolvedBiome = biome ?? self.currentBiome
        
        // Reeling increases tension slightly
        self.lineTension += GameConstants.reelingTensionIncrease
        
        // If tension is low and breathing score is excellent, capture is successful
        if self.currentState == .reeling && self.breathPaceMatchScore >= GameConstants.captureBreathingThreshold && self.lineTension <= GameConstants.captureMaxTension {
            self.currentState = .captured
            let catchResult = CatchTable.lookup(biome: resolvedBiome, bait: self.currentBait ?? .spinnerLures)
            let capturedMonster = Monster(name: catchResult.name, faction: catchResult.faction)
            self.captureSuccessCallback?(capturedMonster)
        }
    }
    
    public func simulateTick() {
        if self.currentState == .casting {
            self.currentState = .waiting
            return
        }
        guard self.currentState == .waiting else { return }
        let decay = self.parasympatheticShiftConfirmed ? 0.0 : GameConstants.patienceDecay
        self.patienceLevel = max(0.0, self.patienceLevel - decay)
        
        // If patience is lost, timeout
        if self.patienceLevel <= 0.0 {
            self.currentState = .idle
            self.currentBait = nil
        }
    }
    
    public func simulateTimeout() {
        guard self.currentState == .waiting else { return }
        self.patienceLevel = 0.0
        self.currentState = .idle
        self.currentBait = nil
    }
    
    public func releaseBuddy() {
        self.currentState = .idle
        self.lineTension = GameConstants.minLineTension
        self.breathPaceMatchScore = 1.0
        self.patienceLevel = 1.0
        self.hrvScore = 60.0
        self.stillnessScore = 1.0
        self.parasympatheticShiftConfirmed = false
        self.sessionBaselineHRV = 60.0
        self.currentBait = nil
    }
}
