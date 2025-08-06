
import UIKit
import StoreKit
import Combine
#if !COCOAPODS
import AppsflyerService
import FacebookService
import AttributionService
import SubscriptionService
import AmplitudeService
import RemoteConfigService
import SentryService
#endif
import AppTrackingTransparency

public actor AppService {
    public static var shared: AppServiceProtocol = internalShared
    static var internalShared = AppService()
    
    public static var uniqueUserID: String? {
        get async {
            return await AttributionManager.shared.uniqueUserID
        }
    }
    
    public static var sentry:SentryServicePublicProtocol {
        return SentryService.shared
    }
    
    public func getUserInfo() -> UserInfo? {
        guard let data = UserDefaults.standard.data(forKey: "appservices.userAttrInfo"),
              let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) else {
            return nil
        }
        return userInfo
    }
    
    public func setUserInfo(_ newValue: UserInfo?) {
        if let newValue {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "appservices.userAttrInfo")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "appservices.userAttrInfo")
        }
    }
    public static var appServicesStatus:[ServiceType: ServiceStatus] {
        get async {
            return await AppServicesStatus.shared.allStatuses()
        }
    }
    
    var attAnswered: Bool = false
    var isConfigured: Bool = false
    var isConfiguredSend: Bool = false
    
    var configuration: AppConfigurationProtocol?
    var appsflyerManager: AppfslyerManagerProtocol?
    nonisolated(unsafe) var appsflyerProxy: AppfslyerManagerProtocol?
    var facebookManager: FacebookManagerProtocol?
    var purchaseManager: SubscriptionManagerProtocol?
    
    var remoteConfigManager: RemoteConfigManager?
    var analyticsManager: AmplitudeManager?
    var sentryManager: SentryServiceProtocol?
    var firebaseManager: FirebaseManager?
    
    var idConfigured = false
    
    var handledNoInternetAlert: Bool = false
    var shouldReconfigure = false
    
    var networkMonitor = NetworkManager()
    
    private var frameworkCallback: ((AppServiceResult) async -> Void)?
    
    func configureAll(configuration: AppConfigurationProtocol, callback: @Sendable @escaping (AppServiceResult) async -> Void) async {
        frameworkCallback = callback
        
        func verifyTestEnvironment(envVariables: [String: String]) -> Bool {
            return envVariables["xctest_skip_config"] != nil
        }
        
        func handleTestEnvironment(envVariables: [String: String]) async -> AppServiceResult {
            if let xc_screen_style_full = environmentVariables["xc_screen_style_full"] {
                let screen_style_full = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "subscription_screen_style_full"})
                screen_style_full?.updateValue(xc_screen_style_full)
            }
            
            if let xc_screen_style_h = environmentVariables["xc_screen_style_h"] {
                let hardPaywall = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "subscription_screen_style_h"})
                hardPaywall?.updateValue(xc_screen_style_h)
            }
            
            if let xc_ab_paywall = environmentVariables["xctest_activePaywallName"] {
                let ab_paywall = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "ab_paywall"})
                ab_paywall?.updateValue(xc_ab_paywall)
            }
            
            let result = AppServiceResult.finished
            
            purchaseManager = SubscriptionManager.shared
            let error = await purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allOfferingsIDs, proIdentifiers: configuration.paywallDataSource.allProOfferingsIDs)
            await AppServicesStatus.shared.updateStatus(.completed(error), for: .subscription)
            return result
        }
        
        func configureServices(configuration: AppConfigurationProtocol) async -> Bool {
            sentryManager = SentryService.shared
            
            if let sentryDataSource = configuration.sentryConfigDataSource {
                let sentryConfig = SentryServiceConfig(dsn: sentryDataSource.dsn,
                                                       debug: sentryDataSource.debug,
                                                       tracesSampleRate: sentryDataSource.tracesSampleRate,
                                                       profilesSampleRate: sentryDataSource.profilesSampleRate,
                                                       shouldCaptureHttpRequests: sentryDataSource.shouldCaptureHttpRequests,
                                                       httpCodesRange: sentryDataSource.httpCodesRange,
                                                       handledDomains: sentryDataSource.handledDomains)
                sentryManager?.configure(sentryConfig)
            }
            
            analyticsManager = AmplitudeManager.shared
            configuration.appSettings.launchCount += 1
            appsflyerManager = AppfslyerManager(config: configuration.appsflyerConfig)
            facebookManager = FacebookManager()
            firebaseManager = FirebaseManager()
            
            purchaseManager = SubscriptionManager.shared
            
            appsflyerProxy = appsflyerManager
            
            remoteConfigManager = RemoteConfigurationManager(deploymentKey: configuration.appSettings.amplitudeDeploymentKey,
                                                             userInfo: [InternalUserProperty.app_environment.key: AppEnvironment.current.rawValue])
            
            let amplitudeCustomURL = configuration.amplitudeDataSource.customServerURL
            let attributionToken = configuration.appSettings.attributionServerSecret
            
            await analyticsManager?.configure(apiKey: configuration.appSettings.amplitudeSecret,
                                              isChinese: AppEnvironment.isChina,
                                              customServerUrl: amplitudeCustomURL)
            
            await withTaskGroup(of: Void.self) { group in
                
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    await self.sendStoreCountryUserProperty()
                }
                
                if configuration.appSettings.isFirstLaunch {
                    group.addTask { [weak self] in
                        guard let self = self else { return }
                        await self.sendAppEnvironmentProperty()
                        await self.sendFirstLaunchEvent()
                    }
                }
                
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let error = await self.purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allOfferingsIDs, proIdentifiers: configuration.paywallDataSource.allProOfferingsIDs)
                    await AppServicesStatus.shared.updateStatus(.completed(error), for: .subscription)
                }
                
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let facebookData = await AttributionFacebookModel(fbUserId: self.facebookManager?.getUserID() ?? "",
                                                                      fbUserData: self.facebookManager?.userData ?? "",
                                                                      fbAnonId: self.facebookManager?.anonUserID ?? "")
                    let appsflyerToken = await self.appsflyerManager?.appsflyerID
                    
                    let installPath = "/install-application"
                    let purchasePath = "/subscribe"
                    let installURLPath = configuration.attServerData.installPath
                    let purchaseURLPath = configuration.attServerData.purchasePath
                    
                    let attributionConfiguration = AttributionConfigData(authToken: attributionToken,
                                                                         installServerURLPath: installURLPath,
                                                                         purchaseServerURLPath: purchaseURLPath,
                                                                         installPath: installPath,
                                                                         purchasePath: purchasePath,
                                                                         appsflyerID: appsflyerToken,
                                                                         appEnvironment: AppEnvironment.current.rawValue,
                                                                         facebookData: facebookData)
                    
                    await AttributionManager.shared.configure(config: attributionConfiguration)
                }
            }
            
            return true
        }
        
        guard isConfigured == false else {
            return
        }
        isConfigured = true
        
        let environmentVariables = ProcessInfo.processInfo.environment
        if verifyTestEnvironment(envVariables: environmentVariables) {
            let result = await handleTestEnvironment(envVariables: environmentVariables)
            await frameworkCallback?(result)
            return
        }
        
        self.configuration = configuration
        
        Task {
            await configureServices(configuration: configuration)
        }
        
        NotificationCenter.default.addObserver(forName:  UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { [weak self] in
                await AppEnvironment.isChina ? self?.chineseFlow() : self?.normalFlow()
            }
        }
    }
    
    private func normalFlow() {
        Task {
            await handleDidBecomeActive()
            await handleAttributionInstall()
            await handleAttributionFinish(isUpdated: false)
            await signForConfigurationFinish()
        }
    }
    
    private func chineseFlow() {
        Task {
            await handleDidBecomeActive()
        }
    }
    
    func reconfigure() async {
        attAnswered = false
        
        await handleAttributionFinish(isUpdated: false)
        await handleAttributionInstall()
        
        await remoteConfigManager?.updateRemoteConfig([:]) { [weak self] in
            guard let self else { return }
            Task {
                await self.remoteConfigManager?.configure(
                    self.configuration?.remoteConfigDataSource.allConfigs ?? []
                ) {
                    Task {
                        let error = await self.remoteConfigManager?.remoteError
                        await AppServicesStatus.shared.updateStatus(.completed(error), for: .remoteConfig)
                    }
                }
            }
        }
        await signForConfigurationFinish()
    }
    
    private func checkIfReconfigNeeded() async {
        if shouldReconfigure && handledNoInternetAlert {
            shouldReconfigure = false
            await reconfigure()
        }
    }
    
    private func handleDidBecomeActive() async {
        if self.configuration?.useDefaultATTRequest == true {
            await self.requestATT()
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.configureID()
            }
            group.addTask { [weak self] in
                await self?.checkIfReconfigNeeded()
            }
            group.addTask { [weak self] in
                if await self?.appsflyerManager?.getCustomerUserID() != nil {
                    try? await self?.appsflyerManager?.startAppsflyer()
                } else {
                    await self?.sentryManager?.log(NSError(domain: "appservices.appsflyer.noCustomerUserID", code: 1001))
                }
            }
            group.addTask { [weak self] in
                await self?.purchaseManager?.updateProductStatus()
            }
        }
        print("handleDidBecomeActiveGroupFinished")
    }
    
    private func configureID() async {
        let savedIDFV = await AttributionManager.shared.installResultData?.idfv
        let uuid = await AttributionManager.shared.savedUserUUID
        let uniqueId = await AttributionManager.shared.uniqueUserID
        
        let id: String?
        if savedIDFV != nil {
            id = await AttributionManager.shared.uniqueUserID
        } else {
            id = uuid ?? uniqueId
        }
        if let id, id != "" {
            guard !idConfigured else {
                return
            }
            print("userID = \(id)")
            idConfigured = true
            await appsflyerManager?.setCustomerUserID(id)
            await purchaseManager?.setUserID(id)
            await facebookManager?.setUserID(id)
            firebaseManager?.configure(id: id)
            sentryManager?.setUserID(id)
            await analyticsManager?.setUserID(id)
            remoteConfigManager?.configure(configuration?.remoteConfigDataSource.allConfigs ?? []) {
                Task {
                    let error = self.remoteConfigManager?.remoteError
                    await AppServicesStatus.shared.updateStatus(.completed(error), for: .remoteConfig)
                }
            }
        }
    }
    
    func requestATT() async {
        let attStatus = ATTrackingManager.trackingAuthorizationStatus
        guard attStatus == .notDetermined else {
            await sendATTProperty(answer: attStatus == .authorized)
            
            guard attAnswered == false else { return }
            attAnswered = true
            await handleATTAnswered(attStatus)
            return
        }
        
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            await self.performATTTimeoutFallback()
        }
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        guard attAnswered == false else { return }
        attAnswered = true
        await sendAttEvent(answer: status == .authorized)
        await handleATTAnswered(status)
    }
    
    private func performATTTimeoutFallback() async {
        guard attAnswered == false else { return }
        attAnswered = true
        await sendAttEvent(answer: false)
        let fallbackStatus = ATTrackingManager.trackingAuthorizationStatus
        await handleATTAnswered(fallbackStatus, error: NSError(domain: "appservices.att.timeout", code: 6456))
    }
    
    func handleATTAnswered(_ status: ATTrackingManager.AuthorizationStatus, error: Error? = nil) async {
        await AppServicesStatus.shared.updateStatus(.completed(error), for: .att_consent)
        if AppEnvironment.isChina {
            await sendConfigurationDelayed(status: [:])
            
            var isReconfigured = false
            
            networkMonitor.monitorInternetChanges { isConnected in
                print("🌐 Network is connected:", isConnected)
                guard isConnected else {
                    return
                }
                
                guard isReconfigured == false else {
                    return
                }
                isReconfigured = true
                Task{
                    await self.reconfigureAfterATT(status, error: error)
                }
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 6) { [weak self] in
                guard isReconfigured == false else {
                    return
                }
                isReconfigured = true
                Task {
                    await self?.reconfigureAfterATT(status, error: error)
                }
            }
        } else {
            await sendConfigurationStarted(status: [:])
            await facebookManager?.configureATT(isAuthorized: status == .authorized)
        }
    }
    
    func reconfigureAfterATT(_ status: ATTrackingManager.AuthorizationStatus, error: Error? = nil) async {
        await sendConfigurationStarted(status: [:])
        await reconfigure()
        attAnswered = true
        await AppServicesStatus.shared.updateStatus(.completed(error), for: .att_consent)
        await facebookManager?.configureATT(isAuthorized: status == .authorized)
        try? await appsflyerManager?.startAppsflyer()
    }
}

// MARK: Attribution Start
extension AppService {
    
    func handleAttributionInstall() async {
        let installPath = "/install-application"
        let purchasePath = "/subscribe"
        
        let installURLPath = await InternalRemoteConfig.install_server_path.internalValue
        let purchaseURLPath = await InternalRemoteConfig.purchase_server_path.internalValue
        if installURLPath != "" && purchaseURLPath != "" {
            let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                 purchaseServerURLPath: purchaseURLPath,
                                                                 installPath: installPath,
                                                                 purchasePath: purchasePath)
            
            await AttributionManager.shared.configureURLs(config: attributionConfiguration)
        } else {
            if let serverDataSource = configuration?.attServerData {
                let installURLPath = serverDataSource.installPath
                let purchaseURLPath = serverDataSource.purchasePath
                
                let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                     purchaseServerURLPath: purchaseURLPath,
                                                                     installPath: installPath,
                                                                     purchasePath: purchasePath)
                
                await AttributionManager.shared.configureURLs(config: attributionConfiguration)
            } else {
                assertionFailure()
            }
        }
        
        let _ = await AttributionManager.shared.syncOnAppStart()
        let error = await AttributionManager.shared.installError
        await AppServicesStatus.shared.updateStatus(.completed(error), for: .attribution)
        await handlePossibleAttributionUpdate()
        print("handleAttributionInstallFinished")
    }
}

// MARK: Attribution finished
extension AppService {
    func handleAttributionFinish(isUpdated: Bool) async {
        let isInternetError = await checkIsNoInternetError()
        
        if isInternetError && checkIsNoInternetHandledOrIgnored() == false && isUpdated == false {
            shouldReconfigure = true
            await frameworkCallback?(.noInternet)
            return
        }
        
        let result = await getAttributionResult()
        
        var attributionDict: [String: String] = ["network": result.network.rawValue]
        if result.userAttribution.isEmpty == false {
            attributionDict += result.userAttribution
        }
        
        let currentUserInfo = getUserInfo()
        
        if currentUserInfo == nil || currentUserInfo?.userSource != result.network {
            setUserInfo(UserInfo(userSource: result.network, attrInfo: result.userAttribution))
            if result.network == .organic {
                await sendUserAttribution(userAttribution: attributionDict, status: [:])
                
                await remoteConfigManager?.updateRemoteConfig([:]) { [weak self] in
                    Task {
                        let error = await self?.remoteConfigManager?.remoteError
                        await AppServicesStatus.shared.updateStatus(.completed(error), for: .remoteConfig)
                    }
                }
            } else {
                if isUpdated {
                    await sendUserAttributionUpdate(userAttribution: attributionDict)
                } else {
                    await sendUserAttribution(userAttribution: attributionDict, status: [:])
                }
                
                await remoteConfigManager?.updateRemoteConfig(attributionDict) { [weak self] in
                    Task {
                        let error = await self?.remoteConfigManager?.remoteError
                        await AppServicesStatus.shared.updateStatus(.completed(error), for: .remoteConfig)
                    }
                }
            }
        } else {
            Task {
                let error = remoteConfigManager?.remoteError
                await AppServicesStatus.shared.updateStatus(.completed(error), for: .remoteConfig)
            }
        }
    }
    
    func getAttributionResult() async -> (network: UserNetworkSource, userAttribution: [String: String]) {
        let deepLinkResult = await appsflyerManager?.getDeeplinkResult() ?? [:]
        let asaResult = await AttributionManager.shared.installResultData
        
        let isIPAT = asaResult?.isIPAT ?? false
        let isASA = (asaResult?.asaAttribution["campaignName"] as? String != nil) ||
        (asaResult?.asaAttribution["campaign_name"] as? String != nil)
        
        var networkSource: UserNetworkSource = .organic
        
        var userAttribution = [String: String]()
        if let networkValue = deepLinkResult["network"] {
            if networkValue == "Full_Access" {
                networkSource = .test_premium
            } else if networkValue.lowercased() == "tiktok_full_access" {
                networkSource = .tiktok_full_access
            } else {
                networkSource = .other(networkValue)
            }
            userAttribution = deepLinkResult
        } else if isIPAT {
            networkSource = .ipat
        } else if isASA {
            networkSource = .asa
            userAttribution = asaResult?.asaAttribution ?? [:]
        }
        
        return (networkSource, userAttribution)
    }
}

// MARK: Attrubution Update
extension AppService {
    func handlePossibleAttributionUpdate() async {
        Task {
            let _ = try? await appsflyerManager?.getDeepLinkInfo(timeout: 10)//???? think about later
            await handleAttributionFinish(isUpdated: true)
        }
    }
}

// MARK: Configuration
extension AppService {
    func signForConfigurationFinish() async {
        guard isConfiguredSend == false else { return }
        isConfiguredSend = true
        await sendConfigurationFinished(status: [:])
        await frameworkCallback?(.finished)
        networkMonitor.stopMonitoring()
    }
}

// MARK: Support
extension AppService {
    func checkIsNoInternetHandledOrIgnored() -> Bool {
        guard AppEnvironment.isChina else {
            return true
        }
        
        guard configuration?.appSettings.isFirstLaunch == true else {
            return true
        }
        
        let noInternetCanBeShown = !handledNoInternetAlert
        guard noInternetCanBeShown else {
            return true
        }
        
        return false
    }
    
    func checkIsNoInternetError() async -> Bool {
        let attrError = await AttributionManager.shared.installError
        let remoteError = remoteConfigManager?.remoteError
        return attrError != nil && remoteError != nil
    }
}

extension AppService {
    public func getDeepLinkInfo(timeout: Double) async throws -> AppfslyerConversionInfo? {
        return try await appsflyerManager?.getDeepLinkInfo(timeout: timeout)
    }
}

// MARK: Purchases
extension AppService {
    func sendPurchaseToServer(_ details: OfferingTransaction) async {
        let attributionModel = AttributionPurchaseModel(details)
        await AttributionManager.shared.syncPurchase(data: attributionModel)
    }
    
    func sendPurchaseToFB(_ purchase: OfferingTransaction) async {
        guard facebookManager != nil else {
            return
        }
        
        let isTrial = purchase.skProduct!.subscription?.introductoryOffer != nil
        let trialPrice = CGFloat(NSDecimalNumber(decimal: purchase.skProduct!.subscription?.introductoryOffer?.price ?? 0).floatValue)
        let price = CGFloat(NSDecimalNumber(decimal: purchase.skProduct!.price).floatValue)
        let currencyCode = purchase.skProduct!.priceFormatStyle.currencyCode
        let analData = FacebookPurchaseData(isTrial: isTrial,
                                            subcriptionID: purchase.skProduct!.id,
                                            trialPrice: trialPrice, price: price,
                                            currencyCode: currencyCode)
        await self.facebookManager?.sendPurchaseAnalytics(analData)
    }
    
    func sendPurchaseToAF(_ purchase: OfferingTransaction) async {
        guard appsflyerManager != nil else {
            return
        }
        
        let isTrial = purchase.skProduct!.subscription?.introductoryOffer != nil
        if isTrial {
            await self.appsflyerManager?.logTrialPurchase()
        }
    }
}
