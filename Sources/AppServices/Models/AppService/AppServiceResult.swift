
import Foundation

public enum AppServiceResult: Hashable, Sendable {
    case finished
    case updated(_ attribution: [String: String])
    case noInternet
    case fcmToken(_ token: String)
}
