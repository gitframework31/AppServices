
import Foundation

internal protocol AttributionServerProcessorProtocol {
    func sendInstallAnalytics(parameters: AttributionInstallRequestModel, authToken: AttributionServerToken,
                              isBackgroundSession: Bool) async -> (dict:[String: String]?, error:Error?)
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel,
                               userId: AttributionUserUUID,
                               authToken: AttributionServerToken,
                               isBackgroundSession: Bool) async -> Bool
    func sendFCMToken(parameters: FCMTokenRequestModel,
                      authToken: AttributionServerToken,
                      isBackgroundSession: Bool,
                      completion: @escaping ((Bool) -> Void))
}
