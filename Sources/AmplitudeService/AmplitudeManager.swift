
import Foundation
import AmplitudeSwift

public actor AmplitudeManager {
    var amplitudeDebugPrint: Bool {
        return true
    }
    
    
    // MARK: - Properties
    public static var shared = AmplitudeManager()
    private var amplitude: Amplitude!
    
    // MARK: - MethodsforceEventsUpload
    public func configure(apiKey: String, isChinese: Bool, customServerUrl: String?) async {
        
        let logger = AmplitudeLogger(logLevel: LogLevel.debug.rawValue)
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey, loggerProvider: logger, autocapture: [.sessions, .networkTracking, .appLifecycles]))
        amplitude.configuration.minTimeBetweenSessionsMillis = 10000
        
        if let customServerUrl, isChinese {
            amplitude.configuration.serverUrl = customServerUrl
        }
    }
    
    public var errorStream: AsyncStream<Error> {
        AmplitudeLogger.eventStream
    }
    
    public func forceUploadEvents() {
        amplitude.flush()
    }
    
    public func setUserID(_ userID: String) {
        guard userID != amplitude.getUserId() else {
            return
        }
        
        amplitude.setUserId(userId: userID)
    }
    
    internal func sendCohortParams() {
        let userDef = UserDefaults.standard
        guard !userDef.bool(forKey: "isCohortSended") else {
            return
        }
        
#if DEBUG
        return
#endif
        userDef.set(true, forKey: "isCohortSended")
        
        let date:Date = Date()
        
        let calendar = Calendar.current
        let monthOfYear = calendar.component(.month, from: date) as Any
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date)! as Any
        let weekOfYear = calendar.ordinality(of: .weekOfYear, in: .year, for: date)! as Any
        
        let identify = Identify()
        identify.setOnce(property: "cohort_date", value: dayOfYear)
        identify.setOnce(property: "cohort_week", value: weekOfYear)
        identify.setOnce(property: "cohort_month", value: monthOfYear)
        
        amplitude.identify(identify: identify)
    }
    
    func saveAttDetails(_ attDetails: [String : NSObject]?) {
        guard let details = attDetails else {
            return
        }
        
        let identify = Identify()
        details.keys.forEach { key in
            identify.set(property: key, value: details[key])
        }
        amplitude.identify(identify: identify)
    }
    
    func log(event: String, with properties: [String: Any] = [String: Any]()) {
        amplitude.track(
            eventType: event,
            eventProperties: properties
        )
        
        if amplitudeDebugPrint {
            if properties.isEmpty {
                print("[AppServices] Amplitude logged \(event.uppercased())")
            } else {
                print("[AppServices] Amplitude logged \(event.uppercased()), properties \(properties)")
            }
        }
    }
    
    func identify(key: String, value: NSObject) {
        let identify = Identify().set(property: key, value: value)
        amplitude.identify(identify: identify)
        
        if amplitudeDebugPrint {
            print("[AppServices] Amplitude identified property: \(key.uppercased()), value: \(value)")
        }
    }
    
    func increment(key: String, value: NSObject) {
        let identify = Identify().add(property: key, value: value as? Int ?? 0)
        amplitude.identify(identify: identify)
        
        if amplitudeDebugPrint {
            print("[AppServices] Analytics incremented property: \(key.uppercased()), value: \(value)")
        }
    }
    
    func setUserProperties(_ userProperties: [String: Any]) {
        amplitude.identify(userProperties: userProperties)
    }
}
