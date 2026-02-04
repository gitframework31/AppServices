import FirebaseAnalytics
import FirebaseCore
import FirebaseMessaging

public class FirebaseService: NSObject {
    public static let shared = FirebaseService()
    
    private var _fcmToken: String?
    private var _userId: String = ""
    
    public var fcmToken: String? {
        return _fcmToken
    }
    
    override private init() {
        super.init()
    }
    
    public func configure(id: String) {
        _userId = id
        FirebaseApp.configure()
        Analytics.logEvent("Firebase Init", parameters: nil)
        Analytics.setUserID(id)
        
        // Set messaging delegate to receive FCM token
        Messaging.messaging().delegate = self
    }
    
    public func registerForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension FirebaseService: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        _fcmToken = token
        
        NotificationCenter.default.post(
            name: NSNotification.Name("FCMTokenUpdated"),
            object: nil,
            userInfo: ["token": token, "userId":_userId]
        )
    }
}
