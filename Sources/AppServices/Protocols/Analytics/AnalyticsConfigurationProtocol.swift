
import Foundation

public protocol AnalyticsConfigurationProtocol {
    associatedtype AnalyticsEvents: AppTrackableEvent
    associatedtype AnalyticsUserProperties: AppAnalyzableUserProperty
    var allEvents: [AnalyticsEvents] { get }
    var allUserProperties: [AnalyticsUserProperties] { get }
    var customServerURL: String? { get }
    var sessionReplayShouldStartOnLaunch: Bool { get }
    var sessionReplaySampleRateValue: Float { get }
    var sessionReplayEnableRemoteConfiguration: Bool { get }
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
    
    var sessionReplayShouldStartOnLaunch: Bool {
        return true
    }
    
    var sessionReplaySampleRateValue: Float {
        return 0.0
    }
    
    var sessionReplayEnableRemoteConfiguration: Bool {
        return true
    }
}
