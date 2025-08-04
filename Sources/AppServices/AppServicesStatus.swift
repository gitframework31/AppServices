import SwiftUI

public enum ServiceStatus {
    case idle
    case initializing
    case ready
    case failed(Error?)
    case completed(Error?)
}

public enum ServiceType: Hashable {
    case att_consent
    case amplitude
    case appsFlyer
    case remoteConfig
    case attribution
    case subscription
}

@globalActor
public enum AppServicesStatus {
    public static let shared = StatusManager()
}

public actor StatusManager {
    private var statuses: [ServiceType: ServiceStatus] = [:]
    
    func updateStatus(_ status: ServiceStatus, for manager: ServiceType) {
        statuses[manager] = status
        logStatusChange(manager: manager, status: status)
    }

    func status(for manager: ServiceType) -> ServiceStatus {
        return statuses[manager] ?? .idle
    }

    func allStatuses() -> [ServiceType: ServiceStatus] {
        return statuses
    }

    private func logStatusChange(manager: ServiceType, status: ServiceStatus) {
        print("AppServicesStatus for: \(manager) → \(status)")
    }
}
