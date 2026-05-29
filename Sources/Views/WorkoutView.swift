import SwiftUI

public struct WorkoutView: View {
    @ObservedObject public var workoutManager: WorkoutRepRestManager
    @ObservedObject public var gameSession: GameSession
    
    @State private var repQuality: Double = 0.8
    @State private var repDuration: Double = 2.0
    
    @State private var bridge: MockHealthKitWorkoutBridge
    
    public init(workoutManager: WorkoutRepRestManager, gameSession: GameSession) {
        self.workoutManager = workoutManager
        self.gameSession = gameSession
        self._bridge = State(initialValue: MockHealthKitWorkoutBridge(manager: workoutManager))
    }
    
    private func stateString(_ state: WorkoutState) -> String {
        switch state {
        case .activeSet: return "Active Set"
        case .restCapture: return "Rest/Capture"
        case .idle: return "Idle"
        }
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Workout Rep/Rest Manager")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .padding(.top, 16)
                
                // Status Readouts
                VStack(alignment: .leading, spacing: 10) {
                    Text("Workout Status")
                        .font(.subheadline)
                        .bold()
                    
                    Text("State: \(stateString(workoutManager.currentState))")
                    Text("Rep Count: \(workoutManager.currentRepCount)")
                    Text("Shield Durability: \(String(format: "%.1f", workoutManager.shieldDurability))%")
                    Text("Set Duration: \(String(format: "%.1f", workoutManager.setDuration))s")
                    Text("Rest Duration: \(String(format: "%.1f", workoutManager.restDuration))s")
                    
                    if let equipped = gameSession.equippedPodmon {
                        Text("Equipped Podmon: \(equipped.name) (Faction: \(equipped.faction.rawValue), Level: \(equipped.level), XP: \(String(format: "%.1f", equipped.xp)))")
                    } else {
                        Text("Equipped Podmon: None")
                            .foregroundStyle(.red.gradient)
                    }
                    
                    ProgressView("Shield Durability", value: workoutManager.shieldDurability, total: 100.0)
                        .animation(.spring(.bouncy), value: workoutManager.shieldDurability)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
                
                // Podmon Mock Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Equip / Mock Podmon")
                        .font(.subheadline)
                        .bold()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            gameSession.equippedPodmon = Podmon.zephyr()
                        }) {
                            Label("Zephyr", systemImage: "wind")
                        }
                        .buttonStyle(FactionButtonStyle(colors: [.teal, .mint], shadowColor: .teal))
                        
                        Button(action: {
                            gameSession.equippedPodmon = Podmon.basalt()
                        }) {
                            Label("Basalt", systemImage: "flame")
                        }
                        .buttonStyle(FactionButtonStyle(colors: [.orange, .red], shadowColor: .orange))
                        
                        Button(action: {
                            gameSession.equippedPodmon = Podmon.lumina()
                        }) {
                            Label("Lumina", systemImage: "sparkles")
                        }
                        .buttonStyle(FactionButtonStyle(colors: [.purple, .indigo], shadowColor: .purple))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
                
                // Base Actions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Base Actions")
                        .font(.subheadline)
                        .bold()
                    
                    HStack(spacing: 15) {
                        Button("Start Workout") {
                            workoutManager.startWorkout()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Start Rest Period") {
                            workoutManager.startRestPeriod()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
                
                // Rep Simulation Control
                VStack(alignment: .leading, spacing: 10) {
                    Text("Perform / Mock Rep")
                        .font(.subheadline)
                        .bold()
                    
                    VStack(alignment: .leading) {
                        Text("Rep Quality: \(String(format: "%.2f", repQuality))")
                        Slider(value: $repQuality, in: 0.0...1.0)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Rep Duration: \(String(format: "%.1f", repDuration))s")
                        Slider(value: $repDuration, in: 0.1...10.0)
                    }
                    
                    Button("Perform Rep") {
                        gameSession.performWorkoutRep(quality: repQuality, duration: repDuration)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(workoutManager.currentState != .activeSet)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
                
                // HealthKit Simulation Control
                VStack(alignment: .leading, spacing: 10) {
                    Text("HealthKit State Bridge Simulation")
                        .font(.subheadline)
                        .bold()
                    
                    HStack(spacing: 12) {
                        Button("HK Running") {
                            bridge.simulateWorkoutStart()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("HK Paused") {
                            bridge.simulateWorkoutPause()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("HK Ended") {
                            bridge.simulateWorkoutEnd()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
            }
            .padding()
            .sensoryFeedback(.impact, trigger: workoutManager.currentRepCount)
        }
    }
}

#Preview {
    let session = GameSession()
    WorkoutView(workoutManager: session.workoutManager, gameSession: session)
}

