
import Foundation
import StoreKit

public enum OfferingType: String {
    case consumable, nonConsumable, nonRenewable, autoRenewable, unknown
}

public enum OfferingPeriod: String {
    case daily, weekly, monthly, quarterly, sixMonths, annual
}

public struct Offering: Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    public static func == (lhs: Offering, rhs: Offering) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public let skProduct: Product
    public let offeringGroup: any AppOfferingGroup
    
    public init(skProduct: Product, offeringGroup: any AppOfferingGroup) {
        self.skProduct = skProduct
        self.offeringGroup = offeringGroup
    }
    
    public var storeKitProduct: Product {
        return skProduct
    }
    
    public var isSubscription: Bool {
        let isSubscription = skProduct.type == .autoRenewable || skProduct.type == .nonRenewable
        return isSubscription
    }
    
    public var offeringType:OfferingType {
        return OfferingType(rawValue: skProduct.type.rawValue) ?? .unknown
    }
    
    public var identifier:String {
        return skProduct.id
    }
    
    public var localizedPrice: String {
        return skProduct.displayPrice
    }
    
    public var localizedIntroductoryPriceString: String? {
        return skProduct.subscription?.introductoryOffer?.displayPrice
    }
    
    public var priceFloat: CGFloat {
        CGFloat(NSDecimalNumber(decimal: skProduct.price).floatValue)
    }
    
    public var isLifetime: Bool {
        return skProduct.id.lowercased().contains("lifetime")
    }
    
    public var isFamilyShareable: Bool {
        return skProduct.isFamilyShareable
    }
    
    public var priceFormatStyle: Decimal.FormatStyle.Currency {
        return skProduct.priceFormatStyle
    }
    
    public var period: OfferingPeriod {
        let count = skProduct.subscription?.subscriptionPeriod.value ?? 0
        switch skProduct.subscription?.subscriptionPeriod.unit {
        case .day:
            if count == 7 {
                return .weekly
            }
            return .daily
        case .week:
            return .weekly
        case .month:
            if count == 3 {
                return .quarterly
            }
            if count == 6 {
                return .sixMonths
            }
            return .monthly
        case .year:
            return .annual
        default:
            return .weekly
        }
    }
    
    public var periodString: String {
        let count = skProduct.subscription?.subscriptionPeriod.value ?? 0
        switch skProduct.subscription?.subscriptionPeriod.unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            if count == 3 {
                return "quarter"
            }
            return "month"
        case .year:
            return "year"
        case nil:
            return ""
        case .some(_):
            return ""
        }
    }
    
    public var trialPeriodString: String {
        switch skProduct.subscription?.introductoryOffer?.period.unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        case nil:
            return ""
        case .some(_):
            return ""
        }
    }
    
    public var periodCount: Int {
        return skProduct.subscription?.subscriptionPeriod.value ?? 0
    }
    
    public var trialCount: Int {
        return skProduct.subscription?.introductoryOffer?.period.value ?? 0
    }
    
    public var currencyCode:String {
        return skProduct.priceFormatStyle.currencyCode
    }
}
