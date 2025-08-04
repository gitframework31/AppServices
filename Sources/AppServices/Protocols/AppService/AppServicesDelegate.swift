
import Foundation

public protocol AppServicesDelegate: AnyObject {
    func appConfigurationFinished(result: AppServiceResult)
    
    func appConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func appConfiguration(handleDeeplinkError error: Error)
}

public extension AppServicesDelegate {
    func appConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        
    }
}
