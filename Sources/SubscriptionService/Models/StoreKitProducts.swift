
import Foundation
import StoreKit

public enum StoreKitProducts {
    case success(products: [Product])
    case error(error: Error)
}
