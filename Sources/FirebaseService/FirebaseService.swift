import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseMessaging

@globalActor
public actor FirebaseActor {
    public static let shared = FirebaseActor()
    private init() {}
}

@FirebaseActor
public final class FirebaseService {
    public static let shared = FirebaseService()
    
    private var internal_fcmToken: String?
    private var userId: String = ""
    private var messagingDelegate: FirebaseMessagingDelegate!
    
    public var fcmToken: String? {
        internal_fcmToken
    }
    
    private init() {}
    
    public func configure(id: String) async {
        userId = id
        
        // Create delegate on MainActor
        let delegate = await FirebaseMessagingDelegate()
        messagingDelegate = delegate
        
        await MainActor.run {
            FirebaseApp.configure()
            Analytics.logEvent("Firebase Init", parameters: nil)
            Analytics.setUserID(id)
            Messaging.messaging().delegate = delegate
        }
    }
    
    public func registerForRemoteNotifications(deviceToken: Data) async {
        await MainActor.run {
            Messaging.messaging().apnsToken = deviceToken
        }
    }
    
    func handleFCMToken(_ token: String) {
        internal_fcmToken = token
        
        let userId = self.userId
        
        Task { @MainActor in
            NotificationCenter.default.post(
                name: NSNotification.Name("FCMTokenUpdated"),
                object: nil,
                userInfo: ["token": token, "userId": userId]
            )
        }
    }
}

@MainActor
private final class FirebaseMessagingDelegate: NSObject, @preconcurrency MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        Task { @FirebaseActor in
            FirebaseService.shared.handleFCMToken(token)
        }
    }
}
