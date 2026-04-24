public struct SessionReplayConfiguration {
    let shouldStartOnLaunch: Bool
    let sampleRateValue: Float
    let enableRemoteConfiguration: Bool
    
    public init(shouldStartOnLaunch: Bool, sampleRateValue: Float, enableRemoteConfiguration: Bool) {
        self.shouldStartOnLaunch = shouldStartOnLaunch
        self.sampleRateValue = sampleRateValue
        self.enableRemoteConfiguration = enableRemoteConfiguration
    }
}
