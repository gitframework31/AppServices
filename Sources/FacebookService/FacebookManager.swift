
import UIKit
import FBSDKCoreKit

public actor FacebookManager: FacebookManagerProtocol {
    
    public init() { }
    
    public func setUserID(_ newValue: String) async {
        AppEvents.shared.userID = newValue
    }
    
    public func getUserID() async -> String {
        return AppEvents.shared.userID ?? ""
    }
    
    public var userData: String {
        get async {
            return AppEvents.shared.getUserData() ?? ""
        }
    }
    
    public var anonUserID: String {
        get async {
            return AppEvents.shared.anonymousID
        }
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    public func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) -> Bool {
        return ApplicationDelegate.shared.application(app, open: url,
                                                      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                      annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
    
    public func configureATT(isAuthorized: Bool) {
        FBSDKCoreKit.Settings.shared.isAdvertiserTrackingEnabled = isAuthorized
        FBSDKCoreKit.Settings.shared.isAdvertiserIDCollectionEnabled = isAuthorized
    }
    
    public func sendPurchaseAnalytics(_ analData: FacebookPurchaseData) {
        if analData.isTrial == true && analData.trialPrice == 0 {
            let nsstr = NSString(string: analData.subcriptionID)
            
            let dict: [AppEvents.ParameterName : Any] = [
                AppEvents.ParameterName.contentID: nsstr,
                AppEvents.ParameterName.currency: NSString(string: analData.currencyCode),
                AppEvents.ParameterName.numItems: NSString(string: "1")
            ]
            
            AppEvents.shared.logEvent(AppEvents.Name.startTrial,
                                      parameters: dict)
            return
        }
        
        let nsstr = NSString(string: analData.subcriptionID)
        
        let dict: [AppEvents.ParameterName : Any] = [
            AppEvents.ParameterName.contentID: nsstr,
            AppEvents.ParameterName.currency: NSString(string: analData.currencyCode),
            AppEvents.ParameterName.numItems: NSString(string: "1")
        ]
        
        AppEvents.shared.logPurchase(amount: Double(analData.price),
                                     currency: analData.currencyCode,
                                     parameters: dict)
    }
}
