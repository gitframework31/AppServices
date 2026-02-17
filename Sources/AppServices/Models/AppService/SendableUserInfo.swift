import Foundation

public struct SendableUserInfo: @unchecked Sendable {
    public let value: [AnyHashable: Any]
    public init(value: [AnyHashable : Any]) {
        self.value = value
    }
}
