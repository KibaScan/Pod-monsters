import SwiftUI
import CoreLocation

public struct BiomeView: View {
    @ObservedObject public var biomeScanner: BiomeScanner
    @ObservedObject public var gameSession: GameSession
    
    @State private var mockLatitude: Double = 37.7749
    @State private var mockLongitude: Double = -122.4194
    @State private var lastScannedCoordinate: CLLocationCoordinate2D? = nil
    @State private var scanError: String? = nil
    
    public init(biomeScanner: BiomeScanner, gameSession: GameSession) {
        self.biomeScanner = biomeScanner
        self.gameSession = gameSession
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Biome Scanner Diagnostic")
                .font(.headline)
            
            // Readouts Group
            VStack(alignment: .leading, spacing: 10) {
                Text("Current Readouts")
                    .font(.subheadline)
                    .bold()
                
                if let coord = lastScannedCoordinate {
                    Text("GPS Coordinate: (\(String(format: "%.4f", coord.latitude)), \(String(format: "%.4f", coord.longitude)))")
                } else {
                    Text("GPS Coordinate: Not Scanned")
                }
                
                if let state = biomeScanner.currentState {
                    Text("Biome Type: \(state.type.rawValue)")
                    Text("Solar Period: \(state.solarPeriod.rawValue)")
                    Text("Tempest Active: \(state.isTempestActive ? "Yes" : "No")")
                    Text("Temperature: \(String(format: "%.1f", state.temperature))°C")
                } else {
                    Text("No Biome Scanned Yet")
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 16))
            
            // Mock Location Input Controls
            VStack(alignment: .leading, spacing: 10) {
                Text("Mock Location Input")
                    .font(.subheadline)
                    .bold()
                
                HStack {
                    Text("Latitude:")
                    Spacer()
                    TextField("Latitude", value: $mockLatitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                }
                Slider(value: $mockLatitude, in: -90...90)
                
                HStack {
                    Text("Longitude:")
                    Spacer()
                    TextField("Longitude", value: $mockLongitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                }
                Slider(value: $mockLongitude, in: -180...180)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 16))
            
            // Scan Button & Status
            VStack(spacing: 10) {
                if biomeScanner.isScanning {
                    ProgressView("Scanning Overpass & Weather...")
                } else {
                    Button("Scan Location") {
                        Task {
                            do {
                                scanError = nil
                                let coordinate = CLLocationCoordinate2D(latitude: mockLatitude, longitude: mockLongitude)
                                _ = try await biomeScanner.scanCurrentLocation(coordinate: coordinate)
                                lastScannedCoordinate = coordinate
                            } catch {
                                scanError = error.localizedDescription
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let error = scanError {
                    Text("Error: \(error)")
                        .foregroundStyle(.red.gradient)
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}

#Preview {
    let session = GameSession()
    BiomeView(biomeScanner: session.biomeScanner, gameSession: session)
}
