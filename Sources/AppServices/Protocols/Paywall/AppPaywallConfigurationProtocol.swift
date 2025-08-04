
import Foundation
import StoreKit

public protocol AppPaywallConfigurationProtocol: CaseIterable {
    associatedtype OfferingIdentifier: AppOfferingIdentifier
    
    var id: String { get }
    var offerings: [OfferingIdentifier] { get }
}

public extension AppPaywallConfigurationProtocol {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func offerings() async -> OfferingsResult? {
        let offerings = await AppService.internalShared.offerings(config: self)
        return offerings
    }
    
}

extension AppPaywallConfigurationProtocol {
    static var allOfferingsIDs: [String] {
        return allOfferings.map({$0.id})
    }
    static var allProOfferingsIDs: [String] {
        return allProOfferings.map({$0.id})
    }
    
    static var allOfferings: [OfferingIdentifier] {
        return OfferingIdentifier.allCases as! [Self.OfferingIdentifier]
    }
    
    static var allProOfferings: [OfferingIdentifier] {
        return OfferingIdentifier.allCases.filter({$0.offeringGroup.isPro})
    }
    
    var activeForPaywallIDs: [String] {
        return offerings.map({$0.id})
    }
    
    var allOfferings: [OfferingIdentifier] {
        return OfferingIdentifier.allCases as! [Self.OfferingIdentifier]
    }
}
