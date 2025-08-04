
import UIKit
import AppsFlyerLib

public actor AppfslyerManager: NSObject {
    
    public func getDeeplinkResult() async -> [String: String]? {
        return UserDefaults.standard.object(forKey: deepLinkResultUDKey) as? [String: String]
    }
    
    public func setDeeplinkResult(_ newValue: [String: String]?) async {
        guard await getDeeplinkResult() == nil, newValue != nil else {
            return
        }
        UserDefaults.standard.set(newValue, forKey: deepLinkResultUDKey)
    }
    
    private var deepLinkResultUDKey = "appservices_appsflyer_deepLinkResult"

    private typealias ConversionDataContinuation = CheckedContinuation<AppfslyerConversionInfo, Error>
    private var conversionDataContinuation: ConversionDataContinuation?
    private var isCollbackReceived = false
    public var deeplinkError: Error? = nil
    private var storedConversionInfo: AppfslyerConversionInfo?
    
    private func setContinuation(_ continuation: ConversionDataContinuation) {
        self.conversionDataContinuation = continuation
    }
    
    private func handleTimeout() {
        if !isCollbackReceived {
            conversionDataContinuation?.resume(throwing: AppsflyerError.timeout)
            conversionDataContinuation = nil
        }
    }
    
    private func updateContinuation(_ result: AppfslyerConversionInfo) {
        isCollbackReceived = true
        conversionDataContinuation?.resume(returning: result)
        conversionDataContinuation = nil
    }
    
    private func updateContinuation(_ error: Error) {
        conversionDataContinuation?.resume(throwing: error)
        conversionDataContinuation = nil
    }
    
    public init(config: AppsflyerConfigurationData) {
        super.init()
        AppsFlyerLib.shared().appsFlyerDevKey = config.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = config.appleAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 30)
#if DEBUG
        AppsFlyerLib.shared().isDebug = true
#else
        AppsFlyerLib.shared().isDebug = false
#endif
    }
    
    private func parseDeepLink(_ conversionInfo: [AnyHashable : Any]) -> [String: String] {
        var appsFlyerProperties = [String: String]()
        let network = conversionInfo["media_source"] as? String
        if let network {
            appsFlyerProperties["network"] = network
        }
        
        let campaign = conversionInfo["campaign"] as? String
        if let campaign {
            appsFlyerProperties["campaignName"] = campaign
        }
        let adSet = conversionInfo["af_adset"] as? String
        if let adSet {
            appsFlyerProperties["adGroupName"] = adSet
        }
        let ad = conversionInfo["af_ad"] as? String
        if let ad {
            appsFlyerProperties["ad"] = ad
        }
        let dpValue = conversionInfo["deep_link_value"] as? String
        let dpValue1 = conversionInfo["af_dp"] as? String
        if let dpValue {
            appsFlyerProperties["deep_link_value"] = dpValue
        } else if let dpValue1 {
            appsFlyerProperties["deep_link_value"] = dpValue1
        }
        return appsFlyerProperties
    }
}

extension AppfslyerManager: AppfslyerManagerProtocol {
    public var appsflyerID: String {
        AppsFlyerLib.shared().getAppsFlyerUID()
    }
    
    public func getCustomerUserID() async -> String? {
        return AppsFlyerLib.shared().customerUserID
    }
    
    public func setCustomerUserID(_ newValue: String?) async {
        AppsFlyerLib.shared().customerUserID = newValue
    }
    
    public nonisolated func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }
    
    public nonisolated func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppsFlyerLib.shared().registerUninstall(deviceToken)
    }
    
    public nonisolated func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) {
        AppsFlyerLib.shared().handleOpen(url, options: options)
    }
    
    public nonisolated func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }
    
    public func startAppsflyer() async throws {
        try await AppsFlyerLib.shared().start()
    }
    
    public func logTrialPurchase() {
        AppsFlyerLib.shared().logEvent(AFEventStartTrial, withValues: [:])
    }
    
    public func getDeepLinkInfo(timeout: Double) async throws -> AppfslyerConversionInfo {
        if let info = storedConversionInfo {
            return info
        }
        if let error = deeplinkError {
            throw error
        }
        
        return try await withCheckedThrowingContinuation({ [weak self] (continuation: ConversionDataContinuation) in
            guard let self = self else {
                return
            }
            
            Task {
                await self.setContinuation(continuation)
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                Task {
                    await self.handleTimeout()
                }
            }
        })
    }
    
    private func storeConversionData(_ info: AppfslyerConversionInfo) async {
        storedConversionInfo = info
    }
    private func setConversionError(_ error: Error?) async {
        deeplinkError = error
    }
}

extension AppfslyerManager: AppsFlyerLibDelegate {
    public nonisolated func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        Task {
            await setConversionError(nil)
            let deepLinkInfo = await parseDeepLink(conversionInfo.toSendable())
            let appfslyerConversionInfo = AppfslyerConversionInfo(conversionInfo: conversionInfo, deepLinkInfo: deepLinkInfo)
            
            await storeConversionData(appfslyerConversionInfo)
            await self.setDeeplinkResult(deepLinkInfo)
            await updateContinuation(appfslyerConversionInfo)
        }
    }
    
    public nonisolated func onConversionDataFail(_ error: Error) {
        Task {
            await setConversionError(error)
            await updateContinuation(error)
        }
    }
    
    public nonisolated func onAppOpenAttributionFailure(_ error: any Error) {
        Task {
            await setConversionError(error)
            await updateContinuation(error)
        }
    }
}

extension Dictionary {
    func toSendable() -> [String: Any] {
        var converted: [String: Any] = [:]
        
        for (key, value) in self {
            if let stringKey = key as? String {
                converted[stringKey] = value
            }
        }
        
        return converted
    }
}


