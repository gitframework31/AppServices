import Foundation

public enum PurchaseResult {
    case success(transaction: OfferingTransaction)
    case userCancelled
    case pending
    case unknown
    case error(_ error: String)
}
