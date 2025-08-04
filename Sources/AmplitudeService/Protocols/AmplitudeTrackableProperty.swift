
import Foundation

public protocol AmplitudeTrackableUserProperty {
    var key: String { get }
}

public extension AmplitudeTrackableUserProperty {
    func log() async {
        await AmplitudeManager.shared.log(event: key)
    }
    
    static func set(userProperties: [String: Any]) async {
        await AmplitudeManager.shared.setUserProperties(userProperties)
    }
    
    func identify(value: String) async {
        await AmplitudeManager.shared.identify(key: key, value: value as NSObject)
    }
    
    func increment() async {
        await AmplitudeManager.shared.increment(key: key, value: NSNumber(integerLiteral: 1))
    }
}
