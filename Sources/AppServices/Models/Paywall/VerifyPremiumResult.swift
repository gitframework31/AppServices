import Foundation

public enum VerifyPremiumResult {
    case premium(offering: Offering)
    case notPremium
    case noInternet
}
