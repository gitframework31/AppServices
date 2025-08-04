
import Foundation

public enum OfferingsResult {
    case success(offerings: [Offering])
    case error(_ error: Error)
}
