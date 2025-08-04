
import Foundation

/// Result of purchase function
public enum PurchaseResult {
    /// - Returns: OfferingTransaction
    case success(transaction: OfferingTransaction)
    case userCancelled
    case pending
    case unknown
    /// - Returns: Error string
    case error(_ error: String)
}
