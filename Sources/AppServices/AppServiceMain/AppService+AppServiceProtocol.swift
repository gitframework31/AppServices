
import Foundation
import UIKit
import AppTrackingTransparency
#if !COCOAPODS
import SubscriptionService
#endif

extension AppService: AppServiceProtocol {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?, appServiceCofig configuration: any AppConfigurationProtocol, status callback: @Sendable @escaping (AppServiceResult) async -> Void) async {
        networkMonitor.startMonitoring()
        await configureAll(configuration: configuration, callback: callback)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) async -> Bool {
        appsflyerManager?.application(app, open: url, options: options)
        return await (facebookManager?.application(app, open: url, options: options) ?? false)
    }
    
    public nonisolated func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        appsflyerProxy?.application(application, continue: userActivity, restorationHandler: restorationHandler) ?? false
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) async {
        appsflyerManager?.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) async {
        appsflyerManager?.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    public func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus) async {
        async let sendAttProperty = sendAttEvent(answer: status == .authorized)
        async let handleAtt = handleATTAnswered(status)
        _ = await (sendAttProperty, handleAtt)
    }
    
    public func handleNoInternetAlertWasShown() {
        handledNoInternetAlert = true
    }
}
