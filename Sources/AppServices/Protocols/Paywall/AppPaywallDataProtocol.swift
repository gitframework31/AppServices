
import Foundation

public protocol AppPaywallDataProtocol {
    associatedtype PaywallConfiguration: AppPaywallConfigurationProtocol
    associatedtype PurchaseGroup: AppOfferingGroup
    
    var allConfigs: [PaywallConfiguration] { get }
    var defaultPaywall: PaywallConfiguration { get }
}

public extension AppPaywallDataProtocol {
    var allConfigs: [PaywallConfiguration] {
        return PaywallConfiguration.allCases as! [Self.PaywallConfiguration]
    }
}

extension AppPaywallDataProtocol {
    var allOfferingsIDs: [String] {
        return PaywallConfiguration.allOfferingsIDs
    }
    var allProOfferingsIDs: [String] {
        return PaywallConfiguration.allProOfferingsIDs
    }
    var allOfferingIdentifiers: [any AppOfferingIdentifier] {
        return PaywallConfiguration.allOfferings
    }
}
