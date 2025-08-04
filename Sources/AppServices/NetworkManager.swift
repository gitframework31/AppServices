import Network
import Foundation

extension NWInterface.InterfaceType: @retroactive CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}

extension NWInterface.InterfaceType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .other: return "other"
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .loopback: return "loopback"
        case .wiredEthernet: return "wiredEthernet"
        @unknown default: return "unexpected"
        }
    }
}

// MARK: - NetworkManager with AsyncStream

//final class NetworkManager {
//    private let monitor: NWPathMonitor
//    private let queue = DispatchQueue(label: "AppNetworkConnectivityMonitor")
//    
//    private(set) var isConnected: Bool = false
//    private(set) var currentConnectionType: NWInterface.InterfaceType?
//    
//    private var streamInitialized = false
//    
//    init() {
//        monitor = NWPathMonitor()
//        startMonitoring(callback: nil)
//    }
//    
//    func startMonitoring(_ isTest: Bool = false, callback: ((Bool) -> Void)?) {
//        // test = true - simulates a network absence, which will be restored after 3 seconds.
//        guard !streamInitialized else { return }
//        
//        streamInitialized = true
//        
//        monitor.pathUpdateHandler = { [weak self] path in
//            guard let self else { return }
//            if isTest {
//                self.isConnected = false
//                self.currentConnectionType = .other
//                callback?(self.isConnected)
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                    self.isConnected = path.status != .unsatisfied
//                    self.currentConnectionType = NWInterface.InterfaceType.allCases.first(where: { path.usesInterfaceType($0) })
//                    callback?(self.isConnected)
//                }
//            }else{
//                self.isConnected = path.status != .unsatisfied
//                self.currentConnectionType = NWInterface.InterfaceType.allCases.first(where: { path.usesInterfaceType($0) })
//                callback?(self.isConnected)
//            }
//        }
//        
//        monitor.start(queue: queue)
//    }
//        
//    func stopMonitoring() {
//        monitor.cancel()
//    }
//    
//}


final class NetworkManager {
    private let queue = DispatchQueue(label: "AppNetworkConnectivityMonitor")
    private let monitor: NWPathMonitor

    private(set) var isConnected = false
    private(set) var currentConnectionType: NWInterface.InterfaceType?
    
    var internetHandlers: [(Bool) -> Void] = []

    init(_ isTest: Bool = false) {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            if isTest {
                self?.isConnected = false
                self?.currentConnectionType = .other
                self?.internetHandlers.forEach { handler in
                    handler(self?.isConnected ?? false)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self?.isConnected = path.status != .unsatisfied
                    self?.currentConnectionType = NWInterface.InterfaceType.allCases.first(where: { path.usesInterfaceType($0) })
                    self?.internetHandlers.forEach { handler in
                        handler(self?.isConnected ?? false)
                    }
                }
            } else {
                self?.isConnected = path.status != .unsatisfied
                self?.currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
                self?.internetHandlers.forEach { handler in
                    handler(self?.isConnected ?? false)
                }
            }
        }
    }

    func startMonitoring() {
        isConnected = monitor.currentPath.status != .unsatisfied
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        internetHandlers.removeAll()
        monitor.cancel()
    }
    
    func monitorInternetChanges(_ completion: @escaping (Bool) -> Void) {
        internetHandlers.append(completion)
        completion(isConnected)
    }
}
