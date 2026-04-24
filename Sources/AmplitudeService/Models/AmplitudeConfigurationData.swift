public struct AmplitudeConfigurationData {
    let apiKey: String
    let isChinese: Bool
    let customServerUrl: String?
    let sessionReplayConfiguration: SessionReplayConfiguration
    
    public init(apiKey: String, isChinese: Bool, customServerUrl: String?, sessionReplayConfiguration: SessionReplayConfiguration) {
        self.apiKey = apiKey
        self.isChinese = isChinese
        self.customServerUrl = customServerUrl
        self.sessionReplayConfiguration = sessionReplayConfiguration
    }
}
