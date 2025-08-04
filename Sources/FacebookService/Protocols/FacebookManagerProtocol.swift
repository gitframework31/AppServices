
import Foundation
import UIKit

public protocol FacebookManagerProtocol {
//    var userID: String { get set }
    func setUserID(_ newValue: String) async
    func getUserID() async -> String
    
    var userData: String { get async }
    var anonUserID: String { get async }
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) async
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) async -> Bool
    func configureATT(isAuthorized: Bool) async
    func sendPurchaseAnalytics(_ analData: FacebookPurchaseData) async
}
