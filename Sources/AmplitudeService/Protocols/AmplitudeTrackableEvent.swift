
import Foundation

public protocol AmplitudeTrackableEvent {
    var key: String { get }
}

public extension AmplitudeTrackableEvent {
    func log() async {
        await AmplitudeManager.shared.log(event: key)
    }
    
    func log(answer: Any) async {
        await AmplitudeManager.shared.log(event: key, with: ["answer": answer])
    }
    
    func log(params: [String: Any]) async {
        await AmplitudeManager.shared.log(event: key, with: params)
    }
}
