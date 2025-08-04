
import Foundation
import StoreKit

public enum StoreKitPurchaseResult {
    case success(transaction: StoreKitTransaction)
    case pending
    case userCancelled
    case unknown
}
