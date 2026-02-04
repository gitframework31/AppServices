
import Foundation
#if !COCOAPODS
import RemoteConfigService
#endif

public protocol AppRemoteConfigurable: CaseIterable, ExtendedRemoteConfigurable {
    static var subscription_screen_style_full: Self { get }
    static var subscription_screen_style_h: Self { get }
    static var rate_us_primary_shown: Self { get }
    static var rate_us_secondary_shown: Self { get }
    static var ab_paywall: Self { get }
    static var minimal_supported_app_version: Self { get }
}
