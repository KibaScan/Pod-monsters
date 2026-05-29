import SwiftUI

public struct FishingView: View {
    @ObservedObject public var fishingEngine: FishingEngine
    @ObservedObject public var gameSession: GameSession
    
    @State private var selectedBait: BaitType = .ironHooks
    @State private var mockHRV: Double = 60.0
    @State private var mockStillness: Double = 1.0
    @State private var mockBreathingRate: Double = 6.0
    @State private var errorMessage: String? = nil
    
    public init(fishingEngine: FishingEngine, gameSession: GameSession) {
        self.fishingEngine = fishingEngine
        self.gameSession = gameSession
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Fishing Engine Diagnostic")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .padding(.top, 16)
                
                // Status Readouts
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fishing Status")
                        .font(.subheadline)
                        .bold()
                    
                    Text("State: \(fishingEngine.currentState.rawValue)")
                    Text("Breath Pace Match Score: \(String(format: "%.2f", fishingEngine.breathPaceMatchScore))")
                    Text("Patience Level: \(String(format: "%.2f", fishingEngine.patienceLevel))")
                    Text("Stillness Score: \(String(format: "%.2f", fishingEngine.stillnessScore))")
                    Text("HRV Score: \(String(format: "%.1f", fishingEngine.hrvScore))")
                    Text("Shift Confirmed: \(fishingEngine.parasympatheticShiftConfirmed ? "Yes" : "No")")
                    
                    if let equipped = gameSession.equippedPodmon {
                        Text("Equipped Podmon: \(equipped.name) (Faction: \(equipped.faction.rawValue), Level: \(equipped.level))")
                    } else {
                        Text("Equipped Podmon: None")
                            .foregroundStyle(.red.gradient)
                    }
                    
                    ProgressView("Line Tension: \(String(format: "%.2f", fishingEngine.lineTension))", value: fishingEngine.lineTension, total: 1.0)
                        .animation(.spring(.bouncy), value: fishingEngine.lineTension)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
                
                // Bait Inventory and Addition
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bait Inventories (Add/View)")
                        .font(.subheadline)
                        .bold()
                    
                    HStack(spacing: 12) {
                        ForEach(BaitType.allCases, id: \.self) { bait in
                            VStack(spacing: 4) {
                                Text(bait.rawValue)
                                    .font(.caption2)
                                Text("\(gameSession.baitInventory[bait, default: 0])")
                                    .bold()
                                Button("+5") {
                                    errorMessage = nil
                                    do {
                                        try gameSession.addBait(bait, count: 5)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
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
                
                // Fishing Gameplay Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gameplay Actions")
                        .font(.subheadline)
                        .bold()
                    
                    HStack {
                        Picker("Bait", selection: $selectedBait) {
                            ForEach(BaitType.allCases, id: \.self) { bait in
                                Text(bait.rawValue).tag(bait)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button("Cast Line") {
                            do {
                                errorMessage = nil
                                try gameSession.castFishingLine(bait: selectedBait)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundStyle(.red.gradient)
                            .font(.caption)
                    }
                    
                    HStack {
                        Button("Tick") {
                            fishingEngine.simulateTick()
                        }
                        .buttonStyle(.bordered)

                        Button("Bite") {
                            fishingEngine.triggerBite()
                        }
                        .buttonStyle(.bordered)

                        Button("Set Hook") {
                            fishingEngine.setHook()
                        }
                        .buttonStyle(.bordered)

                        Button("Reel In") {
                            fishingEngine.reelIn()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
                
                // Mock Bio-Sensory Inputs
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mock Parasympathetic & Breathing Inputs")
                        .font(.subheadline)
                        .bold()
                    
                    VStack(alignment: .leading) {
                        Text("HRV: \(Int(mockHRV))")
                        Slider(value: $mockHRV, in: 20...150)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Stillness: \(String(format: "%.2f", mockStillness))")
                        Slider(value: $mockStillness, in: 0...1.0)
                    }
                    
                    Button("Update Parasympathetic") {
                        fishingEngine.updateParasympatheticData(hrv: mockHRV, stillness: mockStillness)
                    }
                    .buttonStyle(.bordered)
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Breathing Rate: \(String(format: "%.1f", mockBreathingRate)) breaths/min")
                        Slider(value: $mockBreathingRate, in: 2.0...15.0)
                    }
                    
                    Button("Update Breathing Tempo") {
                        fishingEngine.updateBreathingTempo(simulatedRate: mockBreathingRate)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
            }
            .padding()
            .sensoryFeedback(.impact, trigger: fishingEngine.currentState)
        }
    }
}

#Preview {
    let session = GameSession()
    FishingView(fishingEngine: session.fishingEngine, gameSession: session)
}
