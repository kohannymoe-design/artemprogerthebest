import FirebaseRemoteConfig
import Foundation


enum ConfigRetrievalState: Equatable {
    case completed
    case failed(Error)
    case pending
    case rateLimited
    
    static func == (lhs: ConfigRetrievalState, rhs: ConfigRetrievalState) -> Bool {
        switch (lhs, rhs) {
        case (.completed, .completed),
            (.pending, .pending),
            (.rateLimited, .rateLimited):
            return true
        case (.failed(let leftError), .failed(let rightError)):
            return (leftError as NSError) == (rightError as NSError)
        default:
            return false
        }
    }
}

class DynamicConfigService: ObservableObject {
    static let instance = DynamicConfigService()
    
    private var configInstance = RemoteConfig.remoteConfig()
    
    private init() {
        let configSettings = RemoteConfigSettings()
        configSettings.minimumFetchInterval = 0
        configInstance.configSettings = configSettings
        
        configInstance.setDefaults(fromPlist: "RemoteConfigDefaults")
    }
    
    func retrieveTargetUrl() async -> (url: String?, state: ConfigRetrievalState) {
        do {
            let activationResult = try await configInstance.fetchAndActivate()
            
            switch activationResult {
            case .successFetchedFromRemote, .successUsingPreFetchedData:
                let retrievedUrl = configInstance.configValue(forKey: "url_3").stringValue ?? ""
                return (retrievedUrl.isEmpty ? nil : retrievedUrl, .completed)
                
            case .error:
                let configError = NSError(
                    domain: "DynamicConfig",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Configuration retrieval failed"]
                )
                return (nil, .failed(configError))
                
            @unknown default:
                let unknownError = NSError(
                    domain: "DynamicConfig",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown configuration state"]
                )
                return (nil, .failed(unknownError))
            }
            
        } catch let error as NSError {
            if error.domain == RemoteConfigErrorDomain && error.code == RemoteConfigError.throttled.rawValue {
                let cachedValue = configInstance.configValue(forKey: "url_2").stringValue
                let cachedUrl = cachedValue.isEmpty == false ? cachedValue : nil
                return (cachedUrl, .rateLimited)
            }
            
            return (nil, .failed(error))
        }
    }
}
