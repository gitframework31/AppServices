
import Foundation
#if !COCOAPODS
import AmplitudeService
#endif

enum InternalAnalyticsEvent: String, CaseIterable, AmplitudeTrackableEvent {
    case first_launch
    
#warning("Should be removed after tests")
    case framework_entered_foreground
    case framework_start_delayed
    case framework_attribution_started
    
    case framework_attribution
    case framework_attribution_update
    case framework_finished
    case test_distribution
    case att_permission
    
    public var key: String {
        return rawValue
    }
}
