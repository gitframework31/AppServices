
import UIKit

#if !COCOAPODS
import SubscriptionService
import AppsflyerService
import AttributionService
import AmplitudeService
import SentryService
import AttestService
#endif
import AppTrackingTransparency

public protocol AppServiceProtocol {
    static var shared: AppServiceProtocol { get }
        
    static var uniqueUserID: String? { get async }
    static var sentry:SentryServicePublicProtocol { get }
    
    func getUserInfo() async -> UserInfo?
    func setUserInfo(_ newValue: UserInfo?) async
    
    static var appServicesStatus:[ServiceType: ServiceStatus] { get async }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                     appServiceCofig configuration: AppConfigurationProtocol,
                     status callback: @Sendable @escaping (AppServiceResult) async -> Void) async
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) async -> Bool
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)async
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) async
    
    func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus) async
    func handleNoInternetAlertWasShown() async
    
    func getDeepLinkInfo(timeout: Double) async throws -> AppfslyerConversionInfo?

    func purchase(_ offering: Offering, activeController: UIViewController?) async -> PurchaseResult?
    
    /// Purchase subscription or non-consumable
    /// - Parameter offering: selected Offering for purchase
    /// - Parameter promoOffer: selected StoreKit Promo Offer for purchase
    /// - Returns: PurchaseResult
    func purchase(_ offering: Offering, promoOffer:StoreKitPromoOffer, activeController: UIViewController?) async -> PurchaseResult?
    
    /// Verify Premium
    /// Check if the user has an active subscription.
    /// - Returns: VerifyPremiumResult
    func verifyPremium() async -> VerifyPremiumResult?
    
    /// Verify All
    /// Check if the user has an active subscription and/or a non-consumable purchases (lifetime).
    /// - Returns: VerifyAllResult
    func verifyAll() async -> VerifyAllResult?
    
    /// Restore
    /// It will check for active subscriptions and purchased non-consumables.
    /// - Returns: RestoreResult
    func restore() async -> RestoreResult?
    
    /// Restore All
    /// It will check for all purchased subscriptions and non-consumables. (Like all purchase history)
    /// - Returns: RestoreResult
    func restoreAll() async -> RestoreResult?
    
}

public struct UserInfo: Codable {
    public var userSource: UserNetworkSource
    public var attrInfo: [String: String]?
    
    public init(userSource: UserNetworkSource, attrInfo: [String : String]? = nil) {
        self.userSource = userSource
        self.attrInfo = attrInfo
    }
}
