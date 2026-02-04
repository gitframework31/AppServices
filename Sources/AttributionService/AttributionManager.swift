
import Foundation
import AdSupport
import AdServices
import AppTrackingTransparency

public actor AttributionManager {
    public static var shared: AttributionManager = AttributionManager()
    public var uniqueUserID: String? {
        get async {
            return dataProcessor.uuid
        }
    }
    
    var serverProcessor: AttributionServerProcessorProtocol?
    let udProcessor: AttributionUDProcessorProtocol = AttributionUDProcessor()
    let dataProcessor: AttributionDataProcessorProtocol = AttributionDataProcessor()
    
    var authorizationToken: AttributionServerToken!
    var facebookData: AttributionFacebookModel? = nil
    var appsflyerID: String? = nil
    public var installError: Error? = nil
        
    fileprivate func validateToken(_ token: AttributionServerToken?) -> Bool {
        guard authorizationToken != nil else {
            assertionFailure("AttributionManager error: Auth token not found")
            return false
        }
        
        return true
    }
    
    fileprivate func validateInstallAttributed() -> String? {
        let savedUserIDOrNil = udProcessor.getServerUserID()
        return savedUserIDOrNil
    }
    
    fileprivate func collectInstallData() async -> AttributionInstallRequestModel {
        let attributionDetails:AttributionDetails? = await dataProcessor.attributionDetails()
        
        let sdkVersion = dataProcessor.sdkVersion
        let osVersion = dataProcessor.osVersion
        let appVersion = dataProcessor.appVersion
        let isTrackingEnabled = dataProcessor.isAdTrackingEnabled
        let uuid = dataProcessor.uuid
        let idfa = dataProcessor.idfa
        let idfv = dataProcessor.idfv
        let storeCountry = dataProcessor.storeCountry
        
        var saFields: AttributionInstallRequestModel.SAFields?
        if let attributionDetails = attributionDetails {
            if let details = attributionDetails.details {
                saFields = AttributionInstallRequestModel.SAFields(data: details)
            }else{
                saFields = AttributionInstallRequestModel.SAFields(token: attributionDetails.attributionToken )
            }
        }
        
        var fbFields: AttributionInstallRequestModel.FBFields? = nil
        if let data = facebookData {
            fbFields = AttributionInstallRequestModel.FBFields(userId: data.fbUserId, userData: data.fbUserData, anonymousId: data.fbAnonId)
        }
        
        var status: UInt? = nil
        if #available(iOS 14.3, *) {
            status = ATTrackingManager.trackingAuthorizationStatus.rawValue
        }
        
        let parameters = AttributionInstallRequestModel(userId: uuid,
                                                        idfa: idfa,
                                                        idfv: idfv,
                                                        sdkVersion: sdkVersion,
                                                        osVersion: osVersion,
                                                        appVersion: appVersion,
                                                        limitAdTracking: !isTrackingEnabled,
                                                        storeCountry: storeCountry,
                                                        appsflyerId: appsflyerID,
                                                        iosATT: status,
                                                        fb: fbFields, sa: saFields)
        return parameters
    }
    
    fileprivate func sendInstallData(_ data: AttributionInstallRequestModel, authToken: AttributionServerToken) async -> AttributionManagerResult? {
        let result = await serverProcessor?.sendInstallAnalytics(parameters: data, authToken: authorizationToken, isBackgroundSession: false)// wait for timeout in case of no internet
        let response = await handleSendInstallResponse(result?.dict, error: result?.error, parameters: data)
        return response
    }
    
    fileprivate func checkAndSendPurchase(_ details: AttributionPurchaseModel) async {
        let userIdOrNil = udProcessor.getServerUserID()
        
        guard let userId = userIdOrNil else {
            self.udProcessor.savePurchaseData(details)
            return
        }
        
        await formAndSendPurchase(userId: userId, details: details)
    }
    
    fileprivate func checkAndSendSavedPurchase(userId: String) async {
        let savedDataOrNil = udProcessor.getPurchaseData()
        guard let savedData = savedDataOrNil else{
            return
        }

        await formAndSendPurchase(userId: userId, details: savedData)
    }
    
    fileprivate func formAndSendPurchase(userId: String, details: AttributionPurchaseModel) async {
        let subIdentifier = details.subscriptionIdentifier
        let price = details.price
        let introductoryPrice = details.introductoryPrice
        let currency = details.currencyCode
        let purchaseToken = dataProcessor.receiptToken
        let jws = details.jws
        let originalTransactionID = details.originalTransactionID
        let decodedTransaction = details.decodedTransaction
        let uuid = dataProcessor.uuid
        
        let introPrice = introductoryPrice ?? 0
        
        let anal = AttrubutionPurchaseRequestModel(productId: subIdentifier,
                                                           purchaseId: purchaseToken,
                                                           userId: uuid,
                                                           adid: userId,
                                                           version: 2,
                                                           signedTransaction: jws,
                                                           decodedTransaction: decodedTransaction,
                                                           originalTransactionID:originalTransactionID,
                                                           paymentDetails: AttrubutionPurchaseRequestModel.PaymentDetails(price: price,
                                                                                                                          introductoryPrice: introPrice,
                                                                                                                          currency: currency))
        
        let result = await serverProcessor?.sendPurchaseAnalytics(analytics: anal, userId: userId, authToken: authorizationToken, isBackgroundSession: false)
        
        handleSendPurchaseResult(result ?? false, details: details)
    }
    
    fileprivate func handleSendInstallResponse(_ response: [String: String]?, error: Error?,
                                               parameters: AttributionInstallRequestModel) async -> AttributionManagerResult? {
        guard error == nil else {
            self.installError = error
            udProcessor.saveInstallData(parameters)
            return nil
        }
        
        guard let result = response, let uuid = result["uuid"] else {
            self.installError = error
            udProcessor.saveInstallData(parameters)
            return nil
        }
        
        self.installError = nil
        
        var attributionToSend: [String: String]
        var isAB = false
        if let attribution = result as? [String: String] {
            attributionToSend = attribution
            attributionToSend.removeValue(forKey: "uuid")
            attributionToSend.removeValue(forKey: "isAB")
            isAB = ((attribution["isAB"] ?? "0") as NSString).boolValue
        } else {
            attributionToSend = [String: String]()
        }
        
        let idfv = result["idfv"] as? String
        let attrResult = AttributionManagerResult(userUUID: uuid, idfv: idfv,
                                              asaAttribution: attributionToSend, isIPAT: isAB)
        udProcessor.saveInstallResult(attrResult)
        udProcessor.saveServerUserID(uuid)
        udProcessor.deleteSavedInstallData()
        await checkAndSendSavedPurchase(userId: uuid)
        
        return attrResult
    }
    
    fileprivate func handleSendPurchaseResult(_ result: Bool,
                                              details: AttributionPurchaseModel) {
        if result == true {
            udProcessor.deleteSavedPurchaseData()
        } else {
            udProcessor.savePurchaseData(details)
        }
    }
    
    fileprivate func getCorrectUUID() -> String {
        let result: String
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .authorized {
                let idfaOrNil = dataProcessor.idfa
                let uuid = dataProcessor.uuid
                result = idfaOrNil ?? uuid
            } else {
                if let savedGeneratedUUID = udProcessor.getGeneratedToken() {
                    result = savedGeneratedUUID
                } else {
                    let generatedUUID = dataProcessor.generateUniqueToken()
                    udProcessor.saveGeneratedToken(generatedUUID)
                    
                    result = generatedUUID
                }
            }
        } else {
            let idfaOrNil = dataProcessor.idfa
            let uuid = dataProcessor.uuid
            result = idfaOrNil ?? uuid
        }
        
        return result
    }
    
    fileprivate func sendFCMToken(userId: String, fcmToken: String, localization: String, completion: @escaping (Bool) -> Void) {
        let parameters = FCMTokenRequestModel(userId: userId, fcmToken: fcmToken, localization: localization)
        
        serverProcessor?.sendFCMToken(parameters: parameters,
                                   authToken: authorizationToken,
                                   isBackgroundSession: false) { success in
            if success {
                self.udProcessor.saveFCMToken(fcmToken)
            }
            completion(success)
        }
    }
    
    public func checkAndSendSavedFCMToken(fcmToken: String, userId: String, localization: String, completion: @escaping (FcmTokenUpdateResult) -> Void) {
        let savedToken = udProcessor.getFCMToken()
        if savedToken != fcmToken {
            sendFCMToken(userId: userId, fcmToken: fcmToken, localization: localization) { success in
                completion(success ? .updated : .failed)
            }
        }else{
            completion(.notRequired)
        }
    }
    
}

extension AttributionManager: AttributionManagerProtocol {
    public var savedUserUUID: String? {
        get async {
            return udProcessor.getServerUserID()
        }
    }
    
    public var installResultData: AttributionManagerResult? {
        get async {
            return udProcessor.getInstallResult()
        }
    }
    
    public func configure(config: AttributionConfigData) async {
        self.facebookData = config.facebookData
        self.appsflyerID = config.appsflyerID
        authorizationToken = config.authToken
        
        serverProcessor = AttributionServerProcessor(installServerURLPath: config.installServerURLPath,
                                                       purchaseServerURLPath: config.purchaseServerURLPath,
                                                       installPath: config.installPath,
                                                     purchasePath: config.purchasePath,
                                                     tokensPath: config.tokensPath)
    }
    
    public func configureURLs(config: AttributionConfigURLs) async {
        serverProcessor = AttributionServerProcessor(installServerURLPath: config.installServerURLPath,
                                               purchaseServerURLPath: config.purchaseServerURLPath,
                                               installPath: config.installPath,
                                                     purchasePath: config.purchasePath,
                                                     tokensPath: config.tokensPath)
    }
    
    public func syncOnAppStart() async -> AttributionManagerResult? {
        guard validateToken(authorizationToken) else {
            assertionFailure("AttributionManager error: Auth token not found")
            return nil
        }
        
        guard let userID = validateInstallAttributed() else {
            
            let installData: AttributionInstallRequestModel
            if let savedInstallData = udProcessor.getInstallData() {
                installData = savedInstallData
            } else {
                installData = await collectInstallData()
            }
            let data = await sendInstallData(installData, authToken: authorizationToken)
            return data
        }
        
        await checkAndSendSavedPurchase(userId: userID)
        return nil
    }
    
    public func syncPurchase(data: AttributionPurchaseModel) async {
        guard authorizationToken != nil else {
            assertionFailure("AttributionManager error: Auth token not found")
            return
        }
        
        await checkAndSendPurchase(data)
    }
    
}
