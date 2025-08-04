
import Foundation

public protocol RemoteConfigurationProtocol {
    var configurationCompletion: (() -> Void)? { get set }
    
    init(deploymentKey: String, userInfo: [String: String])
}

public protocol RemoteConfigManager {
    var allRemoteValues: [String: String] { get }
    var remoteError: Error? { get }
    
    func configure(_ appConfigurables: [any RemoteConfigurable], completion: @escaping () -> Void)
    
    func updateRemoteConfig(_ appConfigurables: [String: String], completion: @escaping () -> Void) async
    
    func getValue(forConfig config: any RemoteConfigurable) -> String?
    func exposure(forConfig config: RemoteConfigurable)
}
