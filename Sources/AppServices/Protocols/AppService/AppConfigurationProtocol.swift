
import Foundation
#if !COCOAPODS
import AppsflyerService
#endif

public protocol AppConfigurationProtocol {
    var appSettings: AppSettingsProtocol { get }
    var remoteConfigDataSource: any AppRemoteConfigProtocol { get }
    var amplitudeDataSource: any AnalyticsConfigurationProtocol { get }
    var paywallDataSource: any AppPaywallDataProtocol { get }
    var useDefaultATTRequest: Bool { get }
    var configurationTimeout: Int { get }
    var attServerData: any AttributionDataProtocol { get }
    var sentryConfigDataSource: (any SentryDataSourceProtocol)? { get }
}

public extension AppConfigurationProtocol {
    var useDefaultATTRequest: Bool { return true }
    
    var configurationTimeout: Int {
        return 6
    }
    
    var appsflyerConfig: AppsflyerConfigurationData {
        return AppsflyerConfigurationData(appsFlyerDevKey: appSettings.appsFlyerKey,
                                          appleAppID: appSettings.appID)
    }
}
