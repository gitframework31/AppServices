
import Foundation

public protocol AnalyticsConfigurationProtocol {
    associatedtype AnalyticsEvents: AppTrackableEvent
    associatedtype AnalyticsUserProperties: AppAnalyzableUserProperty
    var allEvents: [AnalyticsEvents] { get }
    var allUserProperties: [AnalyticsUserProperties] { get }
    var customServerURL: String? { get }
}

public extension AnalyticsConfigurationProtocol {
    var allEvents: [AnalyticsEvents] {
        return AnalyticsEvents.allCases as! [Self.AnalyticsEvents]
    }

    var allUserProperties: [AnalyticsUserProperties] {
        return AnalyticsUserProperties.allCases as! [Self.AnalyticsUserProperties]
    }
    
    var customServerURL: String? {
        return nil
    }
}
