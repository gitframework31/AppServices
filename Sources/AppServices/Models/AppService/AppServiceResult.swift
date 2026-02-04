
import Foundation

public enum AppServiceResult: Hashable, Sendable {
    case finished
    case noInternet
    case fcmToken(_ token: String)
}
