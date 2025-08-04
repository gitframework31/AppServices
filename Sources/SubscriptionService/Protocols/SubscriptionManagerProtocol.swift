
import Foundation
import StoreKit

public protocol SubscriptionManagerProtocol {
    static var shared: SubscriptionManagerProtocol { get }
    func initialize(allIdentifiers: [String], proIdentifiers: [String]) async -> Error?
    func setUserID(_ id: String) async
    func requestProducts(_ identifiers: [String]) async -> StoreKitProducts
    func requestAllProducts(_ identifiers: [String]) async -> StoreKitProducts
    func updateProductStatus() async
    func purchase(_ product: Product, activeController: UIViewController?) async throws -> StoreKitPurchaseResult
    func purchase(_ product: Product, promoOffer:StoreKitPromoOffer, activeController: UIViewController?) async throws -> StoreKitPurchaseResult
    func restore() async -> StoreKitRestoreResult
    func restoreAll() async -> StoreKitRestoreResult
    func verifyPremium() async -> StoreKitVerifyPremiumResult
    func verifyAll() async -> StoreKitVerifyAllResult
}
