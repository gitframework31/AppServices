
import Foundation

public protocol SentryServiceProtocol {
    func configure(_ data: SentryServiceConfig) async
    func setUserID(_ userID: String)
    func log(_ error: Error)
    func log(_ exception: NSException)
    func log(_ message: String)
    func pauseAppHangTracking()
    func resumeAppHangTracking()
}

public protocol SentryServicePublicProtocol {
    func log(_ error: Error)
    func log(_ exception: NSException)
    func log(_ message: String)
    func pauseAppHangTracking()
    func resumeAppHangTracking()
}
