
import Foundation

public protocol RemoteConfigurable {
    var key: String { get }
    var defaultValue: String { get }
    var value: String { get async }
    var stickyBucketed: Bool { get }
}
