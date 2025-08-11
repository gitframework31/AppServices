
import Foundation
import UIKit
import AppTrackingTransparency
#if !COCOAPODS
import SubscriptionService
#endif

extension AppService: AppServiceProtocol {
    
    public func startAppServices(_ application: UIApplication, _ launchOptions: [UIApplication.LaunchOptionsKey : Any]?, _ configuration: any AppConfigurationProtocol) async -> AsyncStream<AppServiceResult> {
        networkMonitor.startMonitoring()
        return configureAll(configuration: configuration)
    }
    
    public func application(_ app: UIApplication,
                            _ url: URL,
                            _ options: [UIApplication.OpenURLOptionsKey : Any]) async -> Bool {
        appsflyerManager?.application(app, open: url, options: options)
        return await (facebookManager?.application(app, open: url, options: options) ?? false)
    }
    
    public nonisolated func application(_ application: UIApplication, _ userActivity: NSUserActivity, _ restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        appsflyerProxy?.application(application, continue: userActivity, restorationHandler: restorationHandler) ?? false
    }
    
    public func application(_ application: UIApplication, _ deviceToken: Data) async {
        appsflyerManager?.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    public func application(_ application: UIApplication, _ userInfo: SendableUserInfo, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) async {
        appsflyerManager?.application(application, didReceiveRemoteNotification: userInfo.value, fetchCompletionHandler: completionHandler)
    }
    
    public func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus) async {
        async let sendAttProperty: Void = sendAttEvent(answer: status == .authorized)
        async let handleAtt: Void = handleATTAnswered(status)
        _ = await (sendAttProperty, handleAtt)
    }
    
    public func handleNoInternetAlertWasShown() {
        handledNoInternetAlert = true
    }
}
