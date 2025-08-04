import Foundation
import AmplitudeSwift

enum AmplitudeError: Error, LocalizedError {
    case error(message: String)
    
    var errorDescription: String? {
        switch self {
        case .error(let message):
            return message
        }
    }
}

class AmplitudeLogger: Logger {
    typealias LogLevel = LogLevelEnum
    
    var logLevel: Int
    
    private static var eventContinuation: AsyncStream<Error>.Continuation?
    
    static let eventStream: AsyncStream<Error> = {
        AsyncStream { continuation in
            AmplitudeLogger.eventContinuation = continuation
        }
    }()
    
    init(logLevel: Int = LogLevelEnum.OFF.rawValue) {
        self.logLevel = logLevel
    }
    
    func error(message: String) {
        let error: Error = AmplitudeError.error(message: message)
        
        print("⚠️ [Amplitude Error] \(error.localizedDescription)")
        AmplitudeLogger.eventContinuation?.yield(error)
    }
    
    func warn(message: String) {
        print("⚠️ [Amplitude Warn] \(message)")
    }
    
    func log(message: String) {
        //Start flushing 7 events
        print("⚠️ [Amplitude Log] \(message)")
    }
    
    func debug(message: String) {
        //Network connectivity changed to offline.
        print("⚠️ [Amplitude Debug] \(message)")
    }
}

