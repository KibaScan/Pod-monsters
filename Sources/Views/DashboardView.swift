import SwiftUI

@MainActor
public struct DashboardView: View {
    @StateObject var session: GameSession
    
    public init() {
        self._session = StateObject(wrappedValue: GameSession())
    }
    
    public init(session: GameSession) {
        self._session = StateObject(wrappedValue: session)
    }
    
    public var body: some View {
        TabView {
            SniffModeView(motionManager: session.motionManager)
                .tabItem {
                    Label("Sniff Mode", systemImage: "earbuds")
                }
            
            BiomeView(biomeScanner: session.biomeScanner, gameSession: session)
                .tabItem {
                    Label("Biome Scanner", systemImage: "map")
                }
            
            FishingView(fishingEngine: session.fishingEngine, gameSession: session)
                .tabItem {
                    Label("Fishing Engine", systemImage: "fish")
                }
            
            WorkoutView(workoutManager: session.workoutManager, gameSession: session)
                .tabItem {
                    Label("Workout Reps", systemImage: "dumbbell")
                }
        }
    }
}

#Preview {
    DashboardView()
}
