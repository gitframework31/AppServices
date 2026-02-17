import Foundation

public struct UserInfo: Codable {
    public var userSource: UserNetworkSource
    public var attrInfo: [String: String]?
    
    public init(userSource: UserNetworkSource, attrInfo: [String : String]? = nil) {
        self.userSource = userSource
        self.attrInfo = attrInfo
    }
}
