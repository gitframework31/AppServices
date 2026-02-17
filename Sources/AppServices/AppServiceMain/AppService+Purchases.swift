
import Foundation
import StoreKit
#if !COCOAPODS
import SubscriptionService
#endif

extension AppService {
    public func offerings(config:any AppPaywallConfigurationProtocol) async -> OfferingsResult {
        let result = await purchaseManager?.requestProducts(config.activeForPaywallIDs)
        switch result {
        case .success(let products):
            var purchases = mapProducts(products, config)
            purchases = sortOfferings(purchases, ids: config.activeForPaywallIDs)
            return .success(offerings: purchases)
        case .error(let error):
            return .error(error)
        case .none:
            return .error(NSError(domain: "purchaseManager not implemented", code: -1))
        }
    }
    
    public func purchase(_ offering: Offering, activeController: UIViewController?) async -> PurchaseResult? {
        let result = try? await purchaseManager?.purchase(offering.skProduct, activeController: activeController)

        switch result {
        case .success(let purchaseInfo):
            let transaction = OfferingTransaction(skProductId: offering.skProduct.id, skProduct: offering.skProduct, skTransaction: purchaseInfo.transaction, jwsString: purchaseInfo.jwsRepresentation, skOriginalTransactionID: purchaseInfo.originalID, skDecodedTransaction: purchaseInfo.jsonRepresentation)
          
            await sendPurchaseAnalytics(transaction, offering.offeringGroup.isPro)
            return .success(transaction: transaction)
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        case .unknown:
            return .unknown
        case .none:
            return nil
        }
    }
    
    private func sendPurchaseAnalytics(_ transaction: OfferingTransaction, _ isPro: Bool) async {
        if isPro {
            async let sendUserProperty: Void = sendSubscriptionTypeUserProperty(identifier: transaction.skProductId)
            async let sendToAttribution: Void = sendPurchaseToServer(transaction)
            async let sendToFacebook: Void = sendPurchaseToFB(transaction)
            async let sendToAppsflyer: Void = sendPurchaseToAF(transaction)
            
            _ = await (sendUserProperty, sendToAttribution, sendToFacebook, sendToAppsflyer)
        } else {
            async let sendToAttribution: Void = sendPurchaseToServer(transaction)
            async let sendToFacebook: Void = sendPurchaseToFB(transaction)
            async let sendToAppsflyer: Void = sendPurchaseToAF(transaction)
            
            _ = await (sendToAttribution, sendToFacebook, sendToAppsflyer)
        }
    }
    
    public func purchase(_ offering: Offering, promoOffer:StoreKitPromoOffer, activeController: UIViewController?) async -> PurchaseResult? {
        let result = try? await purchaseManager?.purchase(offering.skProduct, promoOffer: promoOffer, activeController: activeController)

        switch result {
        case .success(let purchaseInfo):
            let transaction = OfferingTransaction(skProductId: offering.skProduct.id, skProduct: offering.skProduct, skTransaction: purchaseInfo.transaction, jwsString: purchaseInfo.jwsRepresentation, skOriginalTransactionID: purchaseInfo.originalID, skDecodedTransaction: purchaseInfo.jsonRepresentation)
          
            await sendPurchaseAnalytics(transaction, offering.offeringGroup.isPro)
            return .success(transaction: transaction)
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        case .unknown:
            return .unknown
        case .none:
            return nil
        }
    }
    
    private func groupFor(_ productId: String) -> any AppOfferingGroup {
        let group = configuration?.paywallDataSource.allOfferingIdentifiers.first(where: {$0.id == productId})?.offeringGroup
        return group ?? OfferingDefaultGroup.Pro
    }

    public func verifyPremium() async -> VerifyPremiumResult? {
        if !networkMonitor.isConnected {
            return .noInternet
        }
        let result = await purchaseManager?.verifyPremium()
        if case .premium(let product) = result {
            await sendSubscriptionTypeUserProperty(identifier: product.id)
            return .premium(offering: Offering(skProduct: product, offeringGroup: groupFor(product.id)))
        }else{
            await sendSubscriptionTypeUserProperty(identifier: "")
            return .notPremium
        }
    }
    
    public func verifyAll() async -> VerifyAllResult? {
        let result = await purchaseManager?.verifyAll()
        
        switch result {
        case .success(products: let products):
            let mappedOfferings = products.map({Offering(skProduct: $0, offeringGroup: groupFor($0.id))})
            if let proOffering = mappedOfferings.first(where: {$0.offeringGroup.isPro}) {
                await sendSubscriptionTypeUserProperty(identifier: proOffering.identifier)
            }
            return .success(offerings: mappedOfferings)
        case .none:
            print("[AppServices] purchaseManager not implemented")
            return nil
        }
    }
    
    public func restore() async -> RestoreResult? {
        let result = await purchaseManager?.restore()
        
        switch result {
        case .success(products: let products):
            let mappedOfferings = products.map({Offering(skProduct: $0, offeringGroup: groupFor($0.id))})
            
            if let proOffering = mappedOfferings.first(where: {$0.offeringGroup.isPro}) {
                await sendSubscriptionTypeUserProperty(identifier: proOffering.identifier)
            }
            
            return .restore(offerings: mappedOfferings)
        case .error(let error):
            return .error(error)
        case .none:
            print("[AppServices] purchaseManager not implemented")
            return nil
        }
    }
    
    public func restoreAll() async -> RestoreResult? {
        let result = await purchaseManager?.restoreAll()
        
        switch result {
        case .success(products: let products):
            let mappedOfferings = products.map({Offering(skProduct: $0, offeringGroup: groupFor($0.id))})
            
            if let proOffering = mappedOfferings.first(where: {$0.offeringGroup.isPro}) {
                await sendSubscriptionTypeUserProperty(identifier: proOffering.identifier)
            }
            
            return .restore(offerings: mappedOfferings)
        case .error(let error):
            return .error(error)
        case .none:
            print("[AppServices] purchaseManager not implemented")
            return nil
        }
    }
 
    private func mapProducts(_ skProducts: [Product], _ config:any AppPaywallConfigurationProtocol) -> [Offering] {
        var offerings:[Offering] = []
        skProducts.forEach { product in
            let offeringGroup = config.allOfferings.first(where: {$0.id == product.id})?.offeringGroup
            let offering = Offering(skProduct: product, offeringGroup: offeringGroup ?? OfferingDefaultGroup.Pro)
            offerings.append(offering)
        }
        return offerings
    }
    
    private func sortOfferings(_ offerings: [Offering], ids: [String]) -> [Offering] {
        return offerings.sorted { f, s in
            guard let first = ids.firstIndex(of: f.identifier) else {
                return false
            }

            guard let second = ids.firstIndex(of: s.identifier) else {
                return true
            }

            return first < second
        }
    }
}
