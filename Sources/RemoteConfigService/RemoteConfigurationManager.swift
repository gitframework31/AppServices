
import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public class RemoteConfigurationManager: RemoteConfigManager {
    private var remoteConfigManager: RemoteConfigManager
    
    private var isConfigFetched:Bool = false
    
    public var allRemoteValues: [String: String] {
        return remoteConfigManager.allRemoteValues
    }
    
    public var remoteError: Error? {
        return remoteConfigManager.remoteError
    }
    
    public init(deploymentKey: String, userInfo: [String: String]) {
        remoteConfigManager = ExperimentManager(deploymentKey: deploymentKey, userInfo: userInfo)
    }
    
    public func configure(_ appConfigurables: [any RemoteConfigurable], completion: @escaping () -> Void) {
        guard !isConfigFetched else {
            completion()
            return
        }
        
        remoteConfigManager.configure(appConfigurables) { [weak self] in
            guard let self = self else {return}
            
            isConfigFetched = true
            completion()
        }
    }
    
    public func updateRemoteConfig(_ userProperies: [String: String], completion: @escaping () -> Void) async {
        await remoteConfigManager.updateRemoteConfig(userProperies, completion: completion)
    }
    
    public func getValue(forConfig config: RemoteConfigurable) -> String? {
        return remoteConfigManager.getValue(forConfig: config)
    }
    
    public func exposure(forConfig config: RemoteConfigurable) {
        remoteConfigManager.exposure(forConfig: config)
    }
}
