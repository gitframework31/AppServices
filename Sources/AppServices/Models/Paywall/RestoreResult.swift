
import Foundation

/// Result of Restore function
public enum RestoreResult {
    /// - Returns: An array of Offerings or an empty array.
    case restore(offerings: [Offering])
    /// - Returns: Error string
    case error(_ error: String)
}
