import Foundation

public enum AppsflyerError: Error {
    case timeout
    case alreadyInProgress
    case managerDeallocated
}
