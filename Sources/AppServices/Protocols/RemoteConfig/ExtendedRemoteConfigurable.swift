import Foundation

#if !COCOAPODS
import Experiment
import RemoteConfigService
#else
import AmplitudeExperiment
#endif

public protocol ExtendedRemoteConfigurable: RemoteConfigurable {
    var boolValue: Bool { get async }
    func updateValue(_ newValue: String?)
    func updatePayload(_ newValue: [String: Any]?)
}

public extension ExtendedRemoteConfigurable {
    var value: String {
        get async {
            await updateExposure()
            return await internalValue
        }
    }
    
    func updateValue(_ newValue: String?) {
        setManualReassignValue(with: newValue)
    }
    
    var payload: [String : Any]? {
        get async {
            await updateExposure()
            return await internalPayload
        }
    }
    
    private func updateExposure() async {
        if stickyBucketed && stickyBuckettedValue == nil {
            await setStickyBuckettedValue(with: remoteValue)
        } else if !stickyBucketed && stickyBuckettedValue != nil {
            setStickyBuckettedValue(with: nil)
        }
        
        let value = await internalValue
        
        if lastExposedValue != value {
            setLastExposedValue(newValue: value)
            await exposure()
        }
    }
    
    func updatePayload(_ newValue: [String: Any]?) {
        setManualReassignPayload(with: newValue)
    }
    
    var boolValue: Bool {
        get async {
            switch self {
            default:
                let stringValue = await value.replacingOccurrences(of: " ", with: "")
                switch stringValue {
                case "true", "1":
                    return true
                case "false", "0", "none":
                    return false
                default:
                    assertionFailure()
                    return false
                }
            }
        }
    }
}

extension ExtendedRemoteConfigurable {
    private func exposure() async {
        await AppService.internalShared.remoteConfigManager?.exposure(forConfig: self)
    }
}

extension ExtendedRemoteConfigurable {
    internal var internalValue: String {
        get async {
            if let _ = ProcessInfo.processInfo.environment["xctest_skip_config"] {
                return manualReassignedValue ?? defaultValue
            }
            
            if let manual = manualReassignedValue {
                return manual
            }
            
            if let sticky = stickyBuckettedValue {
                return sticky
            }
            
            return await remoteValue
        }
    }
    
    internal var internalPayload: [String: Any]? {
        get async {
            if let _ = ProcessInfo.processInfo.environment["xctest_skip_config"] {
                return manualReassignedPayload
            }
            
            if let manual = manualReassignedPayload {
                return manual
            }
            
            return await remotePayload
        }
    }
}

extension ExtendedRemoteConfigurable {
    private var remoteValue: String {
        get async {
            await AppService.internalShared.remoteConfigManager?.getValue(forConfig: self) ?? defaultValue
        }
    }
    
    internal var remotePayload: [String: Any]? {
        get async {
            await AppService.internalShared.remoteConfigManager?.getPayload(forConfig: self)
        }
    }
}

extension ExtendedRemoteConfigurable {
    private var manualReassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "internal"+key) as? String
        return savedValue
    }
    
    private func setManualReassignValue(with newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: "internal"+key)
    }
    
    private var manualReassignedPayload: [String: Any]? {
        let savedPayload = UserDefaults.standard.object(forKey: "appservices_" + key + "_payload") as? [String: Any]
        return savedPayload
    }
    
    private func setManualReassignPayload(with newPayload: [String: Any]?) {
        UserDefaults.standard.setValue(newPayload, forKey: "appservices_" + key + "_payload")
    }
}

extension ExtendedRemoteConfigurable {
    private func setStickyBuckettedValue(with newValue: String?) {
        guard let newValue else {
            UserDefaults.standard.removeObject(forKey: "sticky_"+key)
            return
        }
        UserDefaults.standard.setValue(newValue, forKey: "sticky_"+key)
    }
    
    private var stickyBuckettedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "sticky_"+key) as? String
        return savedValue
    }
}

extension ExtendedRemoteConfigurable {
    private var lastExposedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "last_exposed_"+key) as? String
        return savedValue
    }
    
    private func setLastExposedValue(newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: "last_exposed_"+key)
    }
}
