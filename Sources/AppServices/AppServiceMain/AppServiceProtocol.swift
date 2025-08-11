
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
    
    func startAppServices(_ application: UIApplication,
                     _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                     _ configuration: AppConfigurationProtocol) async -> AsyncStream<AppServiceResult>
    
    func application( _ app: UIApplication, _ url: URL, _ options: [UIApplication.OpenURLOptionsKey : Any] ) async -> Bool
    
    func application(_ application: UIApplication,
                     _ userActivity: NSUserActivity,
                     _ restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    
    func application(_ application: UIApplication,
                     _ deviceToken: Data)async
    
    func application(_ application: UIApplication,
                     _ userInfo: SendableUserInfo,
                     _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) async
    
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

public struct SendableUserInfo: @unchecked Sendable {
    public let value: [AnyHashable: Any]
    public init(value: [AnyHashable : Any]) {
        self.value = value
    }
}
