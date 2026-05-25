import XCTest
import CoreLocation
@testable import PodMonsters

@MainActor
final class BiomeTests: XCTestCase {
    
    private func makeUTCDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return utcCalendar.date(from: components)!
    }
    
    func testT1_F4_01_BiomeOverpassParser() async {
        let scanner = BiomeScanner()
        
        // Mock Overpass Response with park tag
        scanner.mockOverpassResponse = "{\"tags\": {\"leisure\": \"park\", \"landuse\": \"grass\"}}"
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.type, .greenSpace)
        } catch {
            XCTFail("Failed to scan current location: \(error)")
        }
    }
    
    func testT1_F4_02_SolarDawnDuskMath() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        // Mock scan date exactly at Dawn solar period (say 5:30 AM local, offset by timezone)
        // 5:30 AM local in NY on May 20, 2026 is 9:30 AM UTC.
        scanner.mockTime = makeUTCDate(year: 2026, month: 5, day: 20, hour: 9, minute: 30)
        
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.solarPeriod, .dawn)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
    
    func testT1_F4_03_WeatherKitTempestMock() async {
        let scanner = BiomeScanner()
        scanner.mockWeatherRainy = true
        let coord = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertTrue(state.isTempestActive)
            XCTAssertEqual(state.temperature, 15.0)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
    
    func testT1_F4_04_BiomeStateCache() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        scanner.mockOverpassResponse = "{\"tags\": {\"leisure\": \"park\"}}"
        
        let state1 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state1?.type, .greenSpace)
        
        // Change mock response, but it should hit cache instead!
        scanner.mockOverpassResponse = "{\"tags\": {\"water\": \"lake\"}}"
        let state2 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state2?.type, .greenSpace) // still greenSpace due to cache hit
    }
    
    func testT1_F4_05_ScannerOfflineFallback() async {
        let scanner = BiomeScanner()
        scanner.shouldFailNetwork = true
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.type, .neutral)
        } catch {
            XCTFail("Offline should fall back gracefully, not throw.")
        }
    }
    
    func testT2_F4_01_PolarGeographicBoundaries() async {
        let scanner = BiomeScanner()
        
        // Extreme Polar coordinate: North Pole
        let polarCoord1 = CLLocationCoordinate2D(latitude: 90.0, longitude: -180.0)
        let state1 = try? await scanner.scanCurrentLocation(coordinate: polarCoord1)
        XCTAssertNotNil(state1)
        XCTAssertNotEqual(state1?.temperature.isNaN, true)
        
        // Invalid extreme coordinates (NaN or Infinite)
        let invalidCoord = CLLocationCoordinate2D(latitude: Double.nan, longitude: Double.infinity)
        let state2 = try? await scanner.scanCurrentLocation(coordinate: invalidCoord)
        XCTAssertEqual(state2?.type, .neutral)
    }
    
    func testT2_F4_02_SolarTwilightBoundary() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0) // equator, easy solar hour
        
        // Exact dawn boundary: 5:00 AM UTC (equator, so 5:00 AM UTC is 5:00 AM solar)
        scanner.mockTime = makeUTCDate(year: 2026, month: 5, day: 20, hour: 5, minute: 0)
        let state1 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state1?.solarPeriod, .dawn)
        
        // Exact dusk boundary: 18:00 UTC (6:00 PM) (equator, so 18:00 UTC is 18:00 solar)
        scanner.mockTime = makeUTCDate(year: 2026, month: 5, day: 20, hour: 18, minute: 0)
        let state2 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state2?.solarPeriod, .dusk)
    }
    
    func testT2_F4_03_EmptyCorruptedOverpassJSON() async {
        let scanner = BiomeScanner()
        scanner.mockOverpassResponse = "Corrupt {{{ data"
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let state = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state?.type, .neutral) // fallback to neutral
    }
    
    func testT2_F4_04_SimultaneousOverlappingScans() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let expectation = self.expectation(description: "Overlapping scans complete")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            Task {
                _ = try? await scanner.scanCurrentLocation(coordinate: coord)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testT2_F4_05_BiomeConfidenceThreshold() async {
        let scanner = BiomeScanner()
        // Provide fuzzy response with no matching keywords
        scanner.mockOverpassResponse = "{\"tags\": {\"building\": \"house\", \"height\": \"2m\"}}"
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let state = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state?.type, .urban) // matched building
    }
    
    func testT2_F4_06_GymPriorityOverUrban() async {
        let scanner = BiomeScanner()
        // A mock JSON representing a gym element which also has building=yes
        scanner.mockOverpassResponse = """
        {
          "elements": [
            {
              "type": "way",
              "id": 1001,
              "tags": {
                "building": "yes",
                "sport": "gym",
                "amenity": "gym"
              }
            }
          ]
        }
        """
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.type, .gym) // Verified: Prioritization matches .gym, not .urban
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
    
    func testT2_F4_07_AvoidFalsePositiveSubstrings() async {
        let scanner = BiomeScanner()
        // A mock JSON of an address way on "Park Avenue", which contains the word "park" in address tags but is not a leisure park.
        scanner.mockOverpassResponse = """
        {
          "elements": [
            {
              "type": "way",
              "id": 1002,
              "tags": {
                "addr:street": "Park Avenue",
                "building": "house"
              }
            }
          ]
        }
        """
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.type, .urban) // Verified: Properly ignores address field, classified as urban due to building
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
    
    func testT2_F4_08_RealNetworkProviderMocking() async {
        // Define a simple mock network client conforming to BiomeNetworkProvider
        struct MockNetworkProvider: BiomeNetworkProvider {
            let dummyJSON: String
            func fetchOverpassData(latitude: Double, longitude: Double) async throws -> String {
                return dummyJSON
            }
        }
        
        let mockJSON = """
        {
          "elements": [
            {
              "type": "node",
              "id": 2001,
              "tags": {
                "natural": "water"
              }
            }
          ]
        }
        """
        
        let provider = MockNetworkProvider(dummyJSON: mockJSON)
        let scanner = BiomeScanner(networkProvider: provider)
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.type, .water) // Verified: Integrated provider works seamlessly
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
    
    func testT2_F4_09_CacheExpirationTTL() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let baseDate = makeUTCDate(year: 2026, month: 5, day: 20, hour: 12, minute: 0)
        
        // Scan 1: initial scan at 12:00
        scanner.mockTime = baseDate
        scanner.mockOverpassResponse = """
        {
          "elements": [
            {
              "type": "way",
              "id": 1003,
              "tags": {
                "leisure": "park"
              }
            }
          ]
        }
        """
        let state1 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state1?.type, .greenSpace)
        
        // Scan 2: scan at 12:10 (within 15-minute TTL, should hit cache)
        scanner.mockTime = baseDate.addingTimeInterval(600) // +10 minutes
        scanner.mockOverpassResponse = """
        {
          "elements": [
            {
              "type": "way",
              "id": 1004,
              "tags": {
                "natural": "water"
              }
            }
          ]
        }
        """
        let state2 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state2?.type, .greenSpace) // cached greenSpace
        
        // Scan 3: scan at 12:20 (past 15-minute TTL, should re-fetch and hit the new mock)
        scanner.mockTime = baseDate.addingTimeInterval(1200) // +20 minutes
        let state3 = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state3?.type, .water) // expired, gets new water biome!
    }
    
    func testEquatorEquinoxSolarPeriods() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        
        // 1. Midnight (00:00 UTC) -> Night
        scanner.mockTime = makeUTCDate(year: 2026, month: 3, day: 20, hour: 0, minute: 0)
        let stateMidnight = try! await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(stateMidnight.solarPeriod, .night)
        
        // 2. Sunrise (06:00 UTC) -> Dawn
        scanner.mockTime = makeUTCDate(year: 2026, month: 3, day: 20, hour: 6, minute: 0)
        let stateSunrise = try! await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(stateSunrise.solarPeriod, .dawn)
        
        // 3. Noon (12:00 UTC) -> Day
        scanner.mockTime = makeUTCDate(year: 2026, month: 3, day: 20, hour: 12, minute: 0)
        let stateNoon = try! await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(stateNoon.solarPeriod, .day)
        
        // 4. Sunset (18:00 UTC) -> Dusk
        scanner.mockTime = makeUTCDate(year: 2026, month: 3, day: 20, hour: 18, minute: 0)
        let stateSunset = try! await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(stateSunset.solarPeriod, .dusk)
    }
    
    func testPolarMidnightSun() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 90.0, longitude: 0.0)
        
        // Summer Solstice (June 21, 2026) -> Midnight Sun (24 hours of Day)
        scanner.mockTime = makeUTCDate(year: 2026, month: 6, day: 21, hour: 0, minute: 0)
        let state = try! await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state.solarPeriod, .day)
    }
    
    func testPolarNight() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 90.0, longitude: 0.0)
        
        // Winter Solstice (December 21, 2026) -> Polar Night (24 hours of Night)
        scanner.mockTime = makeUTCDate(year: 2026, month: 12, day: 21, hour: 12, minute: 0)
        let state = try! await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertEqual(state.solarPeriod, .night)
    }
    
    func testExtremeCoordinateClamping() async {
        let scanner = BiomeScanner()
        let coord = CLLocationCoordinate2D(latitude: 95.0, longitude: 190.0)
        
        scanner.mockTime = makeUTCDate(year: 2026, month: 3, day: 20, hour: 12, minute: 0)
        let state = try? await scanner.scanCurrentLocation(coordinate: coord)
        XCTAssertNotNil(state)
        XCTAssertNotEqual(state?.solarPeriod, .night) // clamped noon is day
    }
    
    func testT3_F4_10_CacheInvalidationOnPrecisionShift() async {
        let scanner = BiomeScanner()
        let coord1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        scanner.mockOverpassResponse = "{\"tags\": {\"leisure\": \"park\"}}"
        let state1 = try? await scanner.scanCurrentLocation(coordinate: coord1)
        XCTAssertEqual(state1?.type, .greenSpace)
        
        // Change mock response
        scanner.mockOverpassResponse = "{\"tags\": {\"water\": \"lake\"}}"
        
        // Scan 2: very tiny shift (within threshold: 1e-5), should still hit cache
        let coord2 = CLLocationCoordinate2D(latitude: 37.774901, longitude: -122.419401)
        let state2 = try? await scanner.scanCurrentLocation(coordinate: coord2)
        XCTAssertEqual(state2?.type, .greenSpace) // hit cache!
        
        // Scan 3: larger shift exceeding precision threshold (e.g. 0.00015 which is > 10^-4), should invalidate and re-fetch!
        let coord3 = CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4194)
        let state3 = try? await scanner.scanCurrentLocation(coordinate: coord3)
        XCTAssertEqual(state3?.type, .water) // cache invalidated, hit new mock!
    }
    
    func testT3_F4_11_InjectedProvidersWorkflow() async {
        let mockNetwork = MockBiomeNetworkProvider(mockResponse: "{\"tags\": {\"indoor\": \"yes\"}}")
        let mockWeather = MockWeatherProvider(mockRainy: true, mockTemperature: 12.0)
        let mockDate = MockDateProvider(mockTime: makeUTCDate(year: 2026, month: 5, day: 20, hour: 18, minute: 0))
        
        let scanner = BiomeScanner(networkProvider: mockNetwork, weatherProvider: mockWeather, dateProvider: mockDate)
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            let state = try await scanner.scanCurrentLocation(coordinate: coord)
            XCTAssertEqual(state.type, .quietIndoor)
            XCTAssertTrue(state.isTempestActive)
            XCTAssertEqual(state.temperature, 12.0)
            XCTAssertEqual(state.solarPeriod, .day)
        } catch {
            XCTFail("Failed scan with injected mock providers: \(error)")
        }
    }
}
