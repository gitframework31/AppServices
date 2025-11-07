
import Foundation
import StoreKit

extension SubscriptionManager {
    
    public func updateProductStatus() async -> Bool {
//        if let task = updateProductStatusTask {
//            await task.value
//            return
//        }
//        
//        let stream = AsyncStream<Void> { continuation in
//            self.updateProductStatusContinuation = continuation
//        }
//        
//        let task = Task {
//            await self.internalUpdateProductStatus()
//            self.updateProductStatusContinuation?.finish()
//        }
//        
//        updateProductStatusTask = task
//        
//        for await _ in stream {}
//        
//        // Clear the task to allow future updates
//        updateProductStatusTask = nil
//        updateProductStatusContinuation = nil
        return await internalUpdateProductStatus()
    }
    
    public func updateAllProductsStatus() async -> [Product] {
        if let task = updateAllProductsStatusTask {
            await task.value
            return self.purchasedAllProducts
        }
        
        let stream = AsyncStream<[Product]> { continuation in
            self.updateAllProductsStatusContinuation = continuation
        }
        
        let task = Task {
            let products = await self.internalUpdateAllProductsStatus()
            self.updateAllProductsStatusContinuation?.yield(products)
            self.updateAllProductsStatusContinuation?.finish()
        }
        
        updateAllProductsStatusTask = task
        
        var productList: [Product] = []
        for await products in stream {
            productList = products
            break
        }
        
        // Clear the task to allow future updates
        updateAllProductsStatusTask = nil
        updateAllProductsStatusContinuation = nil
        
        return productList
    }
    
    private func internalUpdateProductStatus() async -> Bool {
        var purchasedConsumables: [Product] = []
        var purchasedNonConsumables: [Product] = []
        var purchasedSubscriptions: [Product] = []
        var purchasedNonRenewableSubscriptions: [Product] = []
        var purchasedAllProducts: [Product] = []
        
        var isTransactionResultReceived = false
                
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                isTransactionResultReceived = true
                
                switch transaction.productType {
                case .consumable:
                    if let consumable = consumables.first(where: { $0.id == transaction.productID }) {
                        purchasedConsumables.append(consumable)
                        purchasedAllProducts.append(consumable)
                    }
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.append(nonConsumable)
                        purchasedAllProducts.append(nonConsumable)
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(nonRenewable)
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1),
                                                                                   to: transaction.purchaseDate)!
                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                        }
                    }
                case .autoRenewable:
                    if subscriptions.isEmpty {
                        let _ =  await requestAllProducts(self.allIdentifiers)
                    }

                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(subscription)
                        let status = await transaction.subscriptionStatus
                        if status?.state == .subscribed {
                            purchasedSubscriptions.append(subscription)
                        }
                    }
                default:
                    break
                }
            } catch {
                debugPrint("❌ failed to update Product Status \(result.debugDescription).")
            }
        }
                
        self.purchasedConsumables = purchasedConsumables
        self.purchasedNonConsumables = purchasedNonConsumables
        self.purchasedNonRenewables = purchasedNonRenewableSubscriptions
        self.purchasedSubscriptions = purchasedSubscriptions
        self.purchasedAllProducts = purchasedAllProducts
        
        return isTransactionResultReceived
    }
    
    private func internalUpdateAllProductsStatus() async -> [Product] {
        var purchasedAllProducts: [Product] = []
        
        for await result in Transaction.all {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .consumable:
                    if let consumable = consumables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(consumable)
                    }
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(nonConsumable)
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(nonRenewable)
                    }
                case .autoRenewable:
                    if subscriptions.isEmpty {
                        let _ =  await requestAllProducts(self.allIdentifiers)
                    }
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(subscription)
                    }
                default:
                    break
                }
            } catch {
                debugPrint("❌ failed to update All Products Status \(result.debugDescription).")
            }
        }
        
        return purchasedAllProducts
    }
    
    public func getSubscriptionStatus(product: Product) async -> RenewalState? {
        guard let subscription = product.subscription else {
            return nil
        }
        
        do {
            let statuses = try await subscription.status
            
            for status in statuses {
                return status.state
            }
        } catch {
            return nil
        }
        return nil
    }
    
}
