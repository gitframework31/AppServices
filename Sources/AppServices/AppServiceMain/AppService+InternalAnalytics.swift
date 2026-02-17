
import Foundation
#if !COCOAPODS
import AmplitudeService
import AppsflyerService
#endif
import StoreKit

extension AppService {
    func sendAppEnvironmentProperty() async {
        await InternalUserProperty.app_environment.identify(value: AppEnvironment.current.rawValue)
    }
    
    func sendFirstLaunchEvent() async {
        await InternalAnalyticsEvent.first_launch.log()
        await analyticsManager?.forceUploadEvents()
    }
    
    func sendAttEvent(answer: Bool) async {
        async let sendAttProperty: Void = sendATTProperty(answer: answer)
        async let logAtt: Void = InternalAnalyticsEvent.att_permission.log(answer: answer)
        _ = await (sendAttProperty, logAtt)
        await analyticsManager?.forceUploadEvents()
    }
    
    func sendATTProperty(answer: Bool) async {
        await InternalUserProperty.att_status.identify(value: "\(answer)")
    }

    func sendConfigurationDelayed(status: [String: String]) async {
        let internetStatus = ["connection": "\(networkMonitor.isConnected)", "connection_type": networkMonitor.currentConnectionType?.description ?? "unexpected"]
        await InternalAnalyticsEvent.framework_start_delayed.log(params: status+internetStatus)
        await analyticsManager?.forceUploadEvents()
    }

    func sendConfigurationStarted(status: [String: String]) async {
        let internetStatus = ["connection": "\(networkMonitor.isConnected)", "connection_type": networkMonitor.currentConnectionType?.description ?? "unexpected"]
        await InternalAnalyticsEvent.framework_attribution_started.log(params: status+internetStatus)
        await analyticsManager?.forceUploadEvents()
    }

    func sendUserAttribution(userAttribution: [String: String], status: [String: String]) async {
        let internetStatus = ["connection": "\(networkMonitor.isConnected)", "connection_type": networkMonitor.currentConnectionType?.description ?? "unexpected"]
        
        guard userAttribution.isEmpty == false else {
            await InternalAnalyticsEvent.framework_attribution.log(params: status+internetStatus)
            await analyticsManager?.forceUploadEvents()
            return
        }
                
        async let setUserProps: Void = InternalUserProperty.set(userProperties: userAttribution)
        async let logFrameAttribution: Void = InternalAnalyticsEvent.framework_attribution.log(params: userAttribution+status+internetStatus)
        _ = await (setUserProps, logFrameAttribution)
        await analyticsManager?.forceUploadEvents()
    }

    func sendUserAttributionUpdate(userAttribution: [String: String]) async {
        let internetStatus = ["connection": "\(networkMonitor.isConnected)", "connection_type": networkMonitor.currentConnectionType?.description ?? "unexpected"]
        
        guard userAttribution.isEmpty == false else { return }
        
        async let setUserProps: Void = InternalUserProperty.set(userProperties: userAttribution)
        async let logFrameAttribution: Void = InternalAnalyticsEvent.framework_attribution_update.log(params: userAttribution+internetStatus)
        _ = await (setUserProps, logFrameAttribution)
        await analyticsManager?.forceUploadEvents()
    }

    func sendConfigurationFinished(status: [String: String]) async {
        let internetStatus = ["connection": "\(networkMonitor.isConnected)", "connection_type": networkMonitor.currentConnectionType?.description ?? "unexpected"]
        
        await InternalAnalyticsEvent.framework_finished.log(params: status+internetStatus)
        await analyticsManager?.forceUploadEvents()
    }
    
    func sendStoreCountryUserProperty() async {
        Task {
            let country = await Storefront.current?.countryCode ?? ""
            await InternalUserProperty.store_country.identify(value: country)
        }
    }
    
    func sendSubscriptionTypeUserProperty(identifier: String) async {
        await InternalUserProperty.subscription_type.identify(value: identifier)
    }
}
