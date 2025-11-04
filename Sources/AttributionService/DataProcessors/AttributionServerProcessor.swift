
import Foundation

public class AttributionServerProcessor {
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
    
    init(installServerURLPath: String, purchaseServerURLPath: String, installPath: String, purchasePath: String) {
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
    }
    
    fileprivate var isSyncingInstall = false
    
    fileprivate var installURL: URL? {
        let urlPath = "\(installServerURLPath)\(installPath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var subscribeURL: URL? {
        let urlPath = "\(purchaseServerURLPath)\(purchasePath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var session: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config)
        return session
    }
    
    fileprivate var waitingSession: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        return session
    }
    
    fileprivate func createRequest(url: URL, body: Data, authToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("ios", forHTTPHeaderField: "platform")
        request.addValue(authToken, forHTTPHeaderField: "authorization")
        request.httpBody = body
        
        return request
    }
    
    fileprivate func handleServerError() {
        print("""
            \n\n\n
            ==========================
            ATTRIBUTION SERVER DOWN
            ==========================
            \n\n\n
            """)
    }
}

extension AttributionServerProcessor: AttributionServerProcessorProtocol {
    func sendInstallAnalytics(
        parameters: AttributionInstallRequestModel,
        authToken: String,
        isBackgroundSession: Bool = false
    ) async -> (dict:[String: String]?, error:Error?) {
        
        guard let url = installURL,
              let jsonData = try? JSONEncoder().encode(parameters) else {
            print("\n\n\nANALYTICS SEND ERROR\n\n\n")
            return ([:], NSError(domain: "appservices.attribution.internal", code: 400))
        }
        
        guard isSyncingInstall == false else {
            return (nil, nil)
        }

        isSyncingInstall = true
        defer { isSyncingInstall = false }

        var request = createRequest(url: url, body: jsonData, authToken: authToken)
        let taskSession = isBackgroundSession ? waitingSession : session

        do {
            let (data, _) = try await taskSession.data(for: request)
            
            let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: NSObject] ?? [:]
            let result = jsonResult?.reduce(into: [String: String]()) {
                $0[$1.key] = "\($1.value)"
            }
            
            return (result, nil)
            
        } catch {
            handleServerError()

            if !taskSession.configuration.waitsForConnectivity {
                return await sendInstallAnalytics(
                    parameters: parameters,
                    authToken: authToken,
                    isBackgroundSession: true
                )
            }

            return ([:], error)
        }
    }

    
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel, userId: String,
                               authToken: String, isBackgroundSession: Bool = false) async -> Bool {
        guard let url = subscribeURL,
               let jsonData = try? JSONEncoder().encode(analytics) else {
             print("\n\n\nANALYTICS SEND ERROR\n\n\n")
             return false
         }

         let request = createRequest(url: url, body: jsonData, authToken: authToken)
         let taskSession = isBackgroundSession ? waitingSession : session

         do {
             let (data, _) = try await taskSession.data(for: request)
             return data != nil
         } catch {
             handleServerError()
             if !taskSession.configuration.waitsForConnectivity {
                 return await sendPurchaseAnalytics(
                     analytics: analytics,
                     userId: userId,
                     authToken: authToken,
                     isBackgroundSession: true
                 )
             }

             return false
         }
    }
}
