
import Foundation
#if !COCOAPODS
import RemoteConfigService
#endif

public protocol AppSettingsProtocol: AnyObject {
    var appID: String { get }
    var appsFlyerKey: String { get }
    var attributionServerSecret: String { get }
    var subscriptionsSecret: String { get }
    
    var amplitudeSecret: String { get }
    var amplitudeDeploymentKey: String { get }
    
    var launchCount: Int { get set }
    
    var paywallSourceForRestricted: UserNetworkSource? { get }
}

public extension AppSettingsProtocol {
    var isFirstLaunch: Bool {
        launchCount == 1
    }
    
    var paywallSourceForRestricted: UserNetworkSource? {
        return nil
    }
    
    var amplitudeDeploymentKey: String? {
        return nil
    }
}
