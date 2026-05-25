import SwiftUI

public struct SniffModeView: View {
    @ObservedObject public var motionManager: AirPodsMotionManager
    
    @State private var mockYaw: Double = 0.0
    @State private var mockPitch: Double = 0.0
    @State private var mockWobble: Double = 0.0
    
    public init(motionManager: AirPodsMotionManager) {
        self.motionManager = motionManager
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Sniff Mode Radar")
                    .font(.headline)
                
                // Connection & Tracking Status
                HStack {
                    Text("Status: \(motionManager.isTracking ? "Tracking" : "Stopped")")
                    Spacer()
                    Text("Connection: \(motionManager.isConnected ? "Connected" : "Disconnected")")
                }
                .font(.subheadline)
                .padding(.horizontal)
                
                // Visual Radar
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 150, height: 150)
                    
                    // Crosshairs
                    Path { path in
                        path.move(to: CGPoint(x: 75, y: 0))
                        path.addLine(to: CGPoint(x: 75, y: 150))
                        path.move(to: CGPoint(x: 0, y: 75))
                        path.addLine(to: CGPoint(x: 150, y: 75))
                    }
                    .stroke(.secondary.opacity(0.4), lineWidth: 1)
                    
                    // Position Marker
                    let yaw = motionManager.calibrationDelta.yaw
                    let pitch = motionManager.calibrationDelta.pitch
                    let xOffset = max(-75.0, min(75.0, (yaw / 90.0) * 75.0))
                    let yOffset = max(-75.0, min(75.0, (pitch / 90.0) * 75.0))
                    
                    Circle()
                        .fill(.indigo.gradient)
                        .frame(width: 16, height: 16)
                        .offset(x: CGFloat(xOffset), y: CGFloat(yOffset))
                        .animation(.spring(.bouncy), value: xOffset)
                        .animation(.spring(.bouncy), value: yOffset)
                }
                .frame(width: 150, height: 150)
                
                // Digital readouts
                VStack(alignment: .leading, spacing: 5) {
                    Text("Yaw Delta: \(String(format: "%.2f", motionManager.calibrationDelta.yaw))°")
                    Text("Pitch Delta: \(String(format: "%.2f", motionManager.calibrationDelta.pitch))°")
                    Text("Stillness Score: \(String(format: "%.2f", motionManager.stillnessScore))")
                }
                .font(.caption)
                
                // Action Buttons
                HStack(spacing: 15) {
                    Button("Start Tracking") {
                        motionManager.startTracking()
                        motionManager.simulateHeadMovement(yaw: mockYaw, pitch: mockPitch)
                        motionManager.feedMicroMovements(magnitude: mockWobble)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Stop Tracking") {
                        motionManager.stopTracking()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Calibrate") {
                        motionManager.calibrateReferenceAngle()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Simulators
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mock Inputs")
                        .font(.subheadline)
                        .bold()
                    
                    HStack {
                        Text("Yaw: \(Int(mockYaw))°")
                        Slider(value: $mockYaw, in: -180...180)
                            .onChange(of: mockYaw) { _, newValue in
                                if motionManager.isTracking {
                                    motionManager.simulateHeadMovement(yaw: newValue, pitch: mockPitch)
                                }
                            }
                    }
                    
                    HStack {
                        Text("Pitch: \(Int(mockPitch))°")
                        Slider(value: $mockPitch, in: -90...90)
                            .onChange(of: mockPitch) { _, newValue in
                                if motionManager.isTracking {
                                    motionManager.simulateHeadMovement(yaw: mockYaw, pitch: newValue)
                                }
                            }
                    }
                    
                    HStack {
                        Text("Wobble: \(String(format: "%.2f", mockWobble))")
                        Slider(value: $mockWobble, in: 0.0...1.0)
                            .onChange(of: mockWobble) { _, newValue in
                                if motionManager.isTracking {
                                    motionManager.feedMicroMovements(magnitude: newValue)
                                }
                            }
                    }
                    
                    Button("Simulate Head Movement") {
                        motionManager.simulateHeadMovement(yaw: mockYaw, pitch: mockPitch)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!motionManager.isTracking)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 16))
            }
            .padding()
        }
        .sensoryFeedback(.selection, trigger: motionManager.calibrationDelta.yaw)
    }
}

#Preview {
    SniffModeView(motionManager: AirPodsMotionManager())
}
