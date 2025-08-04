
import Foundation
import StoreKit

public enum StoreKitRestoreResult {
    case success(products: [Product])
    case error(_ error: String)
}
