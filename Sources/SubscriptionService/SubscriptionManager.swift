
import StoreKit
import Foundation

public typealias Transaction = StoreKit.Transaction
public typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
public typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public actor SubscriptionManager: NSObject, SubscriptionManagerProtocol {
    // MARK: Variables
    static public let shared: SubscriptionManagerProtocol = internalShared
    public var userId: String = ""
    static var internalShared = SubscriptionManager()
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: Offering Arrays
    var allAvailableProducts: [Product] = []
    public var consumables: [Product] = []
    public var nonConsumables: [Product] = []
    public var subscriptions: [Product] = []
    public var nonRenewables: [Product] = []
    
    public var purchasedConsumables: [Product] = []
    public var purchasedNonConsumables: [Product] = []
    public var purchasedSubscriptions: [Product] = []
    public var purchasedNonRenewables: [Product] = []
    public var purchasedAllProducts: [Product] = []
    
    // MARK: Purchase Identifiers
    var allIdentifiers: [String] = []
    var proIdentifiers: [String] = []
    
    // MARK: updateProductStatus locking mechanism
    var updateProductStatusTask: Task<Void, Never>? = nil
    var updateProductStatusContinuation: AsyncStream<Void>.Continuation?
    
    // MARK: updateAllProductStatus locking mechanism
    var updateAllProductsStatusTask: Task<Void, Never>? = nil
    var updateAllProductsStatusContinuation: AsyncStream<[Product]>.Continuation?
            
    // MARK: initialization
    public func initialize(allIdentifiers: [String], proIdentifiers: [String]) async -> Error? {
        self.allIdentifiers = allIdentifiers
        self.proIdentifiers = proIdentifiers
        
        updateListenerTask = listenForTransactions()
        
        let result = await self.requestAllProducts(allIdentifiers)
        
        let _ = await self.updateProductStatus()
        
        switch result {
        case .success(_):
            return nil
        case .error(let error):
            return error
        }

    }
    
    // MARK: deinit
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: User ID setup
    public func setUserID(_ id: String) {
        self.userId = id
    }
    
    // MARK: Transaction listener
    public func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    let _ = await self.updateProductStatus()
                    await transaction.finish()
                } catch {
                    debugPrint("[AppServices] InApp Transaction verification failed.")
                }
            }
        }
    }
    
    // MARK: Purchase of Product
    public func purchase(_ product: Product, activeController: UIViewController?) async throws -> StoreKitPurchaseResult {
        var options:Set<Product.PurchaseOption> = []
        if let userId = UUID(uuidString: self.userId) {
            options = [.appAccountToken(userId)]
        }
        
        var result: Product.PurchaseResult
        
        if #available (iOS 18.2, *) {
            if let activeController {
                 result = try await product.purchase(confirmIn: activeController, options: options)
            }else{
                 result = try await product.purchase(options: options)
            }
        }else{
             result = try await product.purchase(options: options)
        }
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            let _ = await updateProductStatus()
            await transaction.finish()
            let purchaseInfo = StoreKitTransaction(transaction: transaction, jsonRepresentation: transaction.jsonRepresentation, jwsRepresentation: verification.jwsRepresentation, originalID: "\(transaction.originalID)")
            return .success(transaction: purchaseInfo)
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        default:
            return .unknown
        }
    }
    
    // MARK: Purchase of Product with Promo Offer
    public func purchase(_ product: Product, promoOffer:StoreKitPromoOffer, activeController: UIViewController?) async throws -> StoreKitPurchaseResult {
        var options:Set<Product.PurchaseOption> = []
        if let userId = UUID(uuidString: self.userId) {
            options = [.appAccountToken(userId), .promotionalOffer(offerID: promoOffer.offerID, keyID: promoOffer.keyID, nonce: promoOffer.nonce, signature: promoOffer.signature, timestamp: promoOffer.timestamp)]
        }else{
            options = [.promotionalOffer(offerID: promoOffer.offerID, keyID: promoOffer.keyID, nonce: promoOffer.nonce, signature: promoOffer.signature, timestamp: promoOffer.timestamp)]
        }
        
        var result: Product.PurchaseResult
        
        if #available (iOS 18.2, *) {
            if let activeController {
                 result = try await product.purchase(confirmIn: activeController, options: options)
            }else{
                 result = try await product.purchase(options: options)
            }
        }else{
             result = try await product.purchase(options: options)
        }
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            let _ = await updateProductStatus()
            await transaction.finish()
            let purchaseInfo = StoreKitTransaction(transaction: transaction, jsonRepresentation: transaction.jsonRepresentation, jwsRepresentation: verification.jwsRepresentation, originalID: "\(transaction.originalID)")
            return .success(transaction: purchaseInfo)
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        default:
            return .unknown
        }
    }
    
    // MARK: Restore purchases (only active)
    public func restore() async -> StoreKitRestoreResult {
        do {
            try await AppStore.sync()
        }
        catch {
            return .error(error.localizedDescription)
        }
        var products:[Product] = []
        products.append(contentsOf: self.purchasedConsumables)
        products.append(contentsOf: self.purchasedNonConsumables)
        products.append(contentsOf: self.purchasedSubscriptions)
        products.append(contentsOf: self.purchasedNonRenewables)
        return .success(products: products)
    }
    
    // MARK: Restore all purchases (even expired ones).
    public func restoreAll() async -> StoreKitRestoreResult {
        let allProducts = await updateAllProductsStatus()
        
        return .success(products: allProducts)
    }
    
    // MARK: Verify premium status
    public func verifyPremium() async -> StoreKitVerifyPremiumResult {
        let _ = await updateProductStatus()
        
        var statuses:[StoreKitPremiumProduct] = []
        
        purchasedNonConsumables.forEach { product in
            if proIdentifiers.contains(where: {$0 == product.id}) {
                let premiumStatus = StoreKitPremiumProduct(product: product, state: .subscribed)
                statuses.append(premiumStatus)
            }
        }
        
        purchasedSubscriptions.forEach { product in
            if proIdentifiers.contains(where: {$0 == product.id}) {
                let premiumStatus = StoreKitPremiumProduct(product: product, state: .subscribed)
                statuses.append(premiumStatus)
            }
        }
        
        if let premium = statuses.last(where: {$0.state == .subscribed}) {
            return .premium(purchase: premium.product)
        }else{
            return .notPremium
        }
    }
    
    // MARK: Verify all subscriptions
    public func verifyAll() async -> StoreKitVerifyAllResult {
        let _ = await updateProductStatus()
        
        var products:[Product] = []
        products.append(contentsOf: self.purchasedConsumables)
        products.append(contentsOf: self.purchasedNonConsumables)
        products.append(contentsOf: self.purchasedSubscriptions)
        products.append(contentsOf: self.purchasedNonRenewables)
        return .success(products: products)
    }
    
}


