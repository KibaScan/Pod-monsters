import Foundation

@MainActor
public protocol WellnessSession: AnyObject {
    var type: SessionType { get }
    var equippedPodmonID: UUID { get }
    var startTime: Date? { get }
    var endTime: Date? { get }
    var isRecording: Bool { get }
    
    func start()
    func finalize() async throws -> SessionSummary
}
