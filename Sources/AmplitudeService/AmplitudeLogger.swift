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
        
        print("[AppServices] ⚠️ [Amplitude Error] \(error.localizedDescription)")
        AmplitudeLogger.eventContinuation?.yield(error)
    }
    
    func warn(message: String) {
        print("[AppServices] ⚠️ [Amplitude Warn] \(message)")
    }
    
    func log(message: String) {
        print("[AppServices] ⚠️ [Amplitude Log] \(message)")
    }
    
    func debug(message: String) {
        print("[AppServices] ⚠️ [Amplitude Debug] \(message)")
    }
}

