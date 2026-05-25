import XCTest
import CryptoKit
@testable import PodMonsters

@MainActor
final class GameSessionPersistenceTests: XCTestCase {
    
    private var uniqueTestURL: URL!
    
    override func setUp() {
        super.setUp()
        // Create a unique temporary file path for each test to ensure total isolation
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        uniqueTestURL = tempDir.appendingPathComponent("session_test_\(UUID().uuidString).json")
    }
    
    override func tearDown() {
        // Clean up the temporary file if it was created
        if FileManager.default.fileExists(atPath: uniqueTestURL.path) {
            try? FileManager.default.removeItem(at: uniqueTestURL)
        }
        let sigURL = uniqueTestURL.deletingPathExtension().appendingPathExtension("json.sha256")
        if FileManager.default.fileExists(atPath: sigURL.path) {
            try? FileManager.default.removeItem(at: sigURL)
        }
        // Reset static overrides to maintain pristine state isolation
        GameSession.disableAutoLoadOnTesting = true
        GameSession.testPersistenceURLOverride = nil
        super.tearDown()
    }
    
    func testSuccessfulSaveOfState() {
        let session = GameSession()
        session.customPersistenceURL = uniqueTestURL
        
        session.isSubscriber = true
        session.equippedBuddy = Monster(name: "Basalt", faction: .forge)
        try? session.addBait(.ironHooks, count: 10)
        
        XCTAssertNoThrow(try session.saveToFile())
        
        // Verify that the file was actually written to the unique test URL
        XCTAssertTrue(FileManager.default.fileExists(atPath: uniqueTestURL.path))
        
        // Verify the file content can be decoded
        let data = try? Data(contentsOf: uniqueTestURL)
        XCTAssertNotNil(data)
        
        let state = try? JSONDecoder().decode(GameSessionState.self, from: data!)
        XCTAssertNotNil(state)
        XCTAssertEqual(state?.equippedBuddy?.name, "Basalt")
        XCTAssertEqual(state?.baitInventory[.ironHooks], 15) // default 5 + added 10
        XCTAssertTrue(state?.isSubscriber ?? false)
    }
    
    func testSuccessfulRestoreOfState() {
        let session = GameSession()
        session.customPersistenceURL = uniqueTestURL
        
        session.isSubscriber = true
        session.equippedBuddy = Monster(name: "Lumina", faction: .aether)
        try? session.addBait(.mindBeads, count: 20)
        
        XCTAssertNoThrow(try session.saveToFile())
        
        // Now create a cold launch simulator GameSession
        let newSession = GameSession()
        newSession.customPersistenceURL = uniqueTestURL
        
        XCTAssertNoThrow(try newSession.loadFromFile())
        
        XCTAssertEqual(newSession.equippedBuddy?.name, "Lumina")
        XCTAssertEqual(newSession.baitInventory[.mindBeads], 25) // default 5 + added 20
        XCTAssertTrue(newSession.isSubscriber)
    }
    
    func testSuccessfulColdLaunchRestore() {
        // Save state using session 1
        let session = GameSession()
        session.customPersistenceURL = uniqueTestURL
        session.isSubscriber = true
        session.equippedBuddy = Monster(name: "Lumina", faction: .aether)
        try? session.addBait(.mindBeads, count: 20)
        
        XCTAssertNoThrow(try session.saveToFile())
        
        // Setup static overrides so new sessions during this test run load from uniqueTestURL on init
        GameSession.testPersistenceURLOverride = uniqueTestURL
        GameSession.disableAutoLoadOnTesting = false
        
        // Now create a cold launch simulator GameSession
        let newSession = GameSession()
        
        XCTAssertEqual(newSession.equippedBuddy?.name, "Lumina")
        XCTAssertEqual(newSession.baitInventory[.mindBeads], 25) // default 5 + added 20
        XCTAssertTrue(newSession.isSubscriber)
    }
    
    func testRobustErrorHandlingForCorruptFiles() {
        // Write corrupt/invalid JSON data to the unique URL
        let corruptData = "This is not valid JSON string".data(using: .utf8)!
        try? corruptData.write(to: uniqueTestURL)
        
        // Write a valid signature for corruptData so it passes validation and fails on JSON decode
        let hash = SHA256.hash(data: corruptData)
        let signature = hash.compactMap { String(format: "%02x", $0) }.joined()
        let sigUrl = uniqueTestURL.deletingPathExtension().appendingPathExtension("json.sha256")
        try? Data(signature.utf8).write(to: sigUrl)
        
        let session = GameSession()
        session.customPersistenceURL = uniqueTestURL
        
        // Verifying that loadFromFile throws an error (robust error handling)
        XCTAssertThrowsError(try session.loadFromFile()) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testSignatureMissingThrowsError() {
        let session = GameSession()
        session.customPersistenceURL = uniqueTestURL
        
        session.isSubscriber = true
        session.equippedBuddy = Monster(name: "Basalt", faction: .forge)
        try? session.saveToFile()
        
        // Delete the signature file
        let sigURL = uniqueTestURL.deletingPathExtension().appendingPathExtension("json.sha256")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sigURL.path))
        try? FileManager.default.removeItem(at: sigURL)
        
        // Cold boot loading should throw signatureMissing error
        let restoredSession = GameSession()
        restoredSession.customPersistenceURL = uniqueTestURL
        
        XCTAssertThrowsError(try restoredSession.loadFromFile()) { error in
            XCTAssertEqual(error as? SerializationError, .signatureMissing)
        }
    }
    
    func testSignatureMismatchThrowsError() {
        let session = GameSession()
        session.customPersistenceURL = uniqueTestURL
        
        session.isSubscriber = true
        session.equippedBuddy = Monster(name: "Basalt", faction: .forge)
        try? session.saveToFile()
        
        // Modify/Tamper the JSON state file
        let tamperedData = "{\"equippedBuddy\": null}".data(using: .utf8)!
        try? tamperedData.write(to: uniqueTestURL)
        
        // Cold boot loading should throw signatureMismatch error since signature doesn't match the new content
        let restoredSession = GameSession()
        restoredSession.customPersistenceURL = uniqueTestURL
        
        XCTAssertThrowsError(try restoredSession.loadFromFile()) { error in
            XCTAssertEqual(error as? SerializationError, .signatureMismatch)
        }
    }
    
    func testIsolationUnderUnitTestEnvironments() {
        let session = GameSession()
        
        // Check that persistenceURL automatically resolves to a test path in the temporary directory
        // and does NOT point to the production Library/Application Support path
        let url = session.persistenceURL
        XCTAssertTrue(url.path.contains(NSTemporaryDirectory()))
        XCTAssertTrue(url.lastPathComponent.contains("session_test"))
        XCTAssertFalse(url.path.contains("Library/Application Support/PodMonsters/session.json"))
    }
}
