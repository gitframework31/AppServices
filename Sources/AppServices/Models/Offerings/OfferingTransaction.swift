
import Foundation
import StoreKit
#if !COCOAPODS
import AttributionService
#endif

public struct OfferingTransaction {
    public let skProductId: String
    public let skProduct: Product?
    public let skTransaction: Transaction?
    public let jwsString: String?
    public let skOriginalTransactionID: String?
    public let skDecodedTransaction: Data?
    
    public init(skProductId: String,
                skProduct: Product,
                skTransaction: Transaction,
                jwsString: String?,
                skOriginalTransactionID: String?,
                skDecodedTransaction: Data?) {
        
        self.skProductId = skProductId
        self.skProduct = skProduct
        self.skTransaction = skTransaction
        self.jwsString = jwsString
        self.skOriginalTransactionID = skOriginalTransactionID
        self.skDecodedTransaction = skDecodedTransaction
        
    }
    
    public init() {
        self.skProductId = "skProductId"
        self.skProduct = nil
        self.skTransaction = nil
        self.jwsString = nil
        self.skOriginalTransactionID = nil
        self.skDecodedTransaction = nil
    }
}

extension AttributionPurchaseModel {
    init(_ transaction: OfferingTransaction) {
        let price = CGFloat(NSDecimalNumber(decimal: transaction.skProduct!.price).floatValue)
        let introductoryPrice: CGFloat?
        
        if let introPrice = transaction.skProduct!.subscription?.introductoryOffer?.price {
            introductoryPrice = CGFloat(NSDecimalNumber(decimal: introPrice).floatValue)
        } else {
            introductoryPrice = nil
        }

        let currencyCode = transaction.skProduct!.priceFormatStyle.currencyCode
        let purchaseID = transaction.skProduct!.id
        
        let jws = transaction.jwsString
        let originalTransactionID = transaction.skOriginalTransactionID
        let decodedTransaction = transaction.skDecodedTransaction
        
        self.init(price: price, introductoryPrice: introductoryPrice,
                  currencyCode: currencyCode, subscriptionIdentifier: purchaseID,
                  jws: jws, originalTransactionID: originalTransactionID, decodedTransaction: decodedTransaction)
    }
}
