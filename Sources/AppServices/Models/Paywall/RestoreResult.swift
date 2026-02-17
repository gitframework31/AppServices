import Foundation

public enum RestoreResult {
    case restore(offerings: [Offering])
    case error(_ error: String)
}
