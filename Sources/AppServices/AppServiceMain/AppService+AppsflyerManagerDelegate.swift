
import Foundation
#if !COCOAPODS
import AppsflyerService
#endif

extension AppService: AppsflyerManagerDelegate {
    public func appConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) async {
//        delegate?.appConfiguration(didReceive: deepLinkResult)
    }
    
    public func appConfiguration(handleDeeplinkError error: Error) async {
//        delegate?.appConfiguration(handleDeeplinkError: error)
    }
    
    public func handledDeeplink(_ result: [String : String]) async {
        await handlePossibleAttributionUpdate()
    }
}
public protocol AppsflyerManagerDelegate {
    func handledDeeplink(_ result: [String: String]) async
    
    func appConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) async
    func appConfiguration(handleDeeplinkError error: Error) async

}
