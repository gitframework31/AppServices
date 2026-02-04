
import Foundation

public struct AttributionConfigData {
    let authToken: AttributionServerToken
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
    let appsflyerID: String?
    let appEnvironment: String?
    let facebookData: AttributionFacebookModel?
    let tokensPath: String
    
    public init(authToken: AttributionServerToken, installServerURLPath: String, purchaseServerURLPath: String, installPath: String,
                purchasePath: String, appsflyerID: String?, appEnvironment: String?,
                facebookData: AttributionFacebookModel?, tokensPath: String) {
        self.authToken = authToken
        self.appsflyerID = appsflyerID
        self.facebookData = facebookData
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
        self.appEnvironment = appEnvironment
        self.tokensPath = tokensPath
    }
}

public struct AttributionConfigURLs {
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
    let tokensPath: String
    
    public init(installServerURLPath: String, purchaseServerURLPath: String, installPath: String, purchasePath: String, tokensPath: String) {
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
        self.tokensPath = tokensPath
    }
}
