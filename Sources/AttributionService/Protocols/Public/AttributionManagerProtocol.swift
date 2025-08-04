
import Foundation

public protocol AttributionManagerProtocol {
    static var shared: AttributionManager { get }
    var uniqueUserID: String? { get async }
    var savedUserUUID: String? { get async }
    var installResultData: AttributionManagerResult? { get async }

    func configure(config: AttributionConfigData) async
    func configureURLs(config: AttributionConfigURLs) async
    func syncOnAppStart() async -> AttributionManagerResult?
    func syncPurchase(data: AttributionPurchaseModel) async
}
