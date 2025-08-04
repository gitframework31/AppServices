
import Foundation

public protocol AttributionDataProtocol {
    associatedtype AttributionEndpoints: AttributionConfigProtocol
}

extension AttributionDataProtocol {
    var installPath: String {
        return AttributionEndpoints.install_server_path.rawValue
    }
    var purchasePath: String {
        return AttributionEndpoints.purchase_server_path.rawValue
    }
}
