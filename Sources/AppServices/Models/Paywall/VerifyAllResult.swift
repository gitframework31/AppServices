
import Foundation

/// Result of Verify All Premium function
public enum VerifyAllResult {
    /// - Returns: An array of Offerings or an empty array.
    case success(offerings: [Offering])
}
