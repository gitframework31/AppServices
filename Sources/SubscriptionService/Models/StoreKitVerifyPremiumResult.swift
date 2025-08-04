
import Foundation
import StoreKit

public enum StoreKitVerifyPremiumResult {
    case premium(purchase: Product)
    case notPremium
}
