
import Foundation

/// Result of Verify Premium function
public enum VerifyPremiumResult {
    /// - Returns: An active Offering
    case premium(offering: Offering)
    case notPremium
    case noInternet
}
