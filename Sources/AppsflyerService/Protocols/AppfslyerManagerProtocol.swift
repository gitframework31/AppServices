
import UIKit

public protocol AppfslyerManagerProtocol {
    var appsflyerID: String { get async}

    func getCustomerUserID() async -> String?
    func setCustomerUserID(_ newValue: String?) async
    
    func getDeeplinkResult() async -> [String: String]?
    func hasConversionDataBeenReceived() async -> Bool
    func waitForConversionDataOnFirstLaunch(timeout: TimeInterval) async -> [String: String]
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] )
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    func startAppsflyer() async throws
    func logTrialPurchase() async
    
    func getDeepLinkInfo(timeout: Double) async throws -> AppfslyerConversionInfo
}
