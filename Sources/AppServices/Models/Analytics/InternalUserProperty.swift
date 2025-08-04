
import Foundation
#if !COCOAPODS
import AmplitudeService
#endif

enum InternalUserProperty: String, CaseIterable, AmplitudeTrackableUserProperty {
    case app_environment
    case att_status
    case store_country
    case subscription_type

    public var key: String {
        return rawValue
    }
}
