import Foundation

#if !COCOAPODS
import RemoteConfigService
#endif

public protocol AppRemoteConfigProtocol {
    associatedtype AppRemoteConfigs: AppRemoteConfigurable
    
    var allConfigs: [AppRemoteConfigs] { get }
    
    var allRemoteKeys: [String] { get }
}

public extension AppRemoteConfigProtocol {
    var allConfigs: [AppRemoteConfigs] {
        return AppRemoteConfigs.allCases as! [Self.AppRemoteConfigs]
    }
    
    var allRemoteKeys: [String] {
        let allConfigKeys: [String] = allConfigs.map { $0.key }
        return allConfigKeys
    }
}
