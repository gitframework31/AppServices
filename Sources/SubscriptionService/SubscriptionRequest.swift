
import Foundation
import StoreKit

extension SubscriptionManager {
    
    public func requestProducts(_ identifiers: [String]) async -> StoreKitProducts {
        guard !identifiers.isEmpty else {
            return .error(error: NSError(domain: "empty identifiers", code: -1))
        }
        
        do {
            let storeProducts = try await Product.products(for: identifiers)
            return .success(products: storeProducts)
        } catch {
            return .error(error: error)
        }
    }
    
    public func requestAllProducts(_ identifiers: [String]) async -> StoreKitProducts {
        guard !identifiers.isEmpty else {
            return .error(error: NSError(domain: "empty identifiers", code: -1))
        }
        
        do {
            let storeProducts = try await Product.products(for: identifiers)
            
            allAvailableProducts = storeProducts
    
            mapProducts(storeProducts)

            return .success(products: storeProducts)
        } catch {
            return .error(error: error)
        }
    }
    
    private func mapProducts(_ storeProducts: [Product]) {
        var newConsumables: [Product] = []
        var newNonConsumables: [Product] = []
        var newSubscriptions: [Product] = []
        var newNonRenewables: [Product] = []

        for product in storeProducts {
            switch product.type {
            case .consumable:
                newConsumables.append(product)
            case .nonConsumable:
                newNonConsumables.append(product)
            case .autoRenewable:
                newSubscriptions.append(product)
            case .nonRenewable:
                newNonRenewables.append(product)
            default:
                debugPrint("mapProducts unknown product : \(product).")
            }
        }

        consumables = sortByPrice(newConsumables)
        nonConsumables = sortByPrice(newNonConsumables)
        subscriptions = sortByPrice(newSubscriptions)
        nonRenewables = sortByPrice(newNonRenewables)
    }

    private func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }
    
}
