# AppServices iOS Framework

A comprehensive Swift Package Manager framework that integrates multiple essential services for iOS mobile app development, providing analytics, attribution, subscriptions, remote configuration, error tracking, and more.

## 🚀 Features

### Core Services
- **📊 Analytics** - Amplitude integration for user behavior tracking
- **🎯 Attribution** - AppsFlyer integration for marketing attribution
- **💰 Subscriptions** - StoreKit 2 wrapper for in-app purchases and subscriptions
- **⚙️ Remote Configuration** - Amplitude Experiment integration
- **🐛 Error Tracking** - Sentry integration for crash reporting and error monitoring
- **🔒 App Attestation** - iOS App Attest service integration for app integrity verification
- **📱 Facebook Integration** - Facebook SDK integration for social attribution
- **🌐 Custom Attribution Management** - Custom attribution tracking and server communication

### Key Capabilities
- **Unified Service Management** - Single entry point for all integrated services
- **Async/Await Support** - Modern Swift concurrency throughout the framework
- **Automatic Configuration** - Streamlined setup with protocol-based configuration
- **Network Monitoring** - Built-in network connectivity monitoring
- **ATT Compliance** - App Tracking Transparency integration
- **Service Status Monitoring** - Real-time status tracking for all services

## 📋 Requirements

- iOS 15.0+
- Swift 5.10+
- Xcode 14.0+

## 📦 Installation

### Swift Package Manager

Add AppServices to your project using Swift Package Manager:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL - https://github.com/gitframework31/AppServices.git
3. Select the version you want to use
4. Choose the products you need:
   - `AppServices` (main framework)
   - Individual service modules as needed

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gitframework31/AppServices.git", from: "0.9.0")
]
```

### Available Products

The framework is modular - you can import individual services or the complete framework:

```swift
// Complete framework
import AppServices

// Individual services
import AmplitudeService
import AppsflyerService
import FacebookService
import RemoteConfigService
import AttributionService
import SentryService
import SubscriptionService
import AttestService
```

## 🛠 Configuration

### 1. Create Configuration Object

Implement the [`AppConfigurationProtocol`](Sources/AppServices/Protocols/AppService/AppConfigurationProtocol.swift) to provide your app's configuration:

```swift
import AppServices

class AppConfiguration: AppConfigurationProtocol {
    var appSettings: AppSettingsProtocol { return AppSettings() }
    var remoteConfigDataSource: any AppRemoteConfigProtocol { return RemoteConfigDataSource() }
    var amplitudeDataSource: any AnalyticsConfigurationProtocol { return AmplitudeDataSource() }
    var paywallDataSource: any AppPaywallDataProtocol { return PaywallDataSource() }
    var attServerData: any AttributionDataProtocol { return AttributionDataSource() }
    var sentryConfigDataSource: (any SentryDataSourceProtocol)? { return SentryDataSource() }
    
    var useDefaultATTRequest: Bool { return true }
    var configurationTimeout: Int { return 6 }
}
```

### 2. Implement App Settings

Create your app settings by implementing [`AppSettingsProtocol`](Sources/AppServices/Protocols/AppService/AppSettingsProtocol.swift):

```swift
class AppSettings: AppSettingsProtocol {
    var appID: String { return "your-app-id" }
    var appsFlyerKey: String { return "your-appsflyer-key" }
    var attributionServerSecret: String { return "your-attribution-secret" }
    var subscriptionsSecret: String { return "your-subscription-secret" }
    var amplitudeSecret: String { return "your-amplitude-key" }
    var amplitudeDeploymentKey: String { return "your-deployment-key" }
    
    var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: "launch_count") }
        set { UserDefaults.standard.set(newValue, forKey: "launch_count") }
    }
}
```

## 🚀 Usage

### Basic Setup

Initialize AppServices in your [`AppDelegate`](Sources/AppServices/AppServiceMain/AppServiceProtocol.swift):

```swift
import AppServices
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let configuration = AppConfiguration()
        
        Task {
            await AppService.shared.application(
                application,
                didFinishLaunchingWithOptions: launchOptions,
                appServiceConfig: configuration
            ) { result in
                switch result {
                case .finished:
                    print("AppServices configured successfully")
                case .noInternet:
                    print("No internet connection - will retry when available")
                }
            }
        }
        
        return true
    }
}
```

### Handle App Lifecycle Events

```swift
// Handle URL schemes
func application(_ app: UIApplication, 
                open url: URL, 
                options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    Task {
        return await AppService.shared.application(app, open: url, options: options)
    }
}

// Handle push notifications
func application(_ application: UIApplication, 
                didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task {
        await AppService.shared.application(application, 
                                          didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

// Handle ATT permission changes
func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus) {
    Task {
        await AppService.shared.handleATTPermission(status)
    }
}
```

### Working with Subscriptions

```swift
import AppServices

// Purchase a subscription
let offering = // your offering object
let result = await AppService.shared.purchase(offering, activeController: viewController)

// Verify premium status
let premiumResult = await AppService.shared.verifyPremium()
if premiumResult?.isPremium == true {
    // User has active subscription
}

// Restore purchases
let restoreResult = await AppService.shared.restore()

// Check all purchases (including lifetime)
let verifyAllResult = await AppService.shared.verifyAll()
```

### Attribution and Deep Links

```swift
// Get deep link information
do {
    let conversionInfo = try await AppService.shared.getDeepLinkInfo(timeout: 10.0)
    // Handle attribution data
} catch {
    print("Failed to get deep link info: \(error)")
}

// Get user attribution info
let userInfo = await AppService.shared.getUserInfo()
print("User source: \(userInfo?.userSource)")

if userInfo?.userSource == .test_premium {
    //do some logic here
}
```

### Service Status Monitoring

```swift
// Check status of all services
let statuses = await AppService.appServicesStatus
for (service, status) in statuses {
    switch status {
    case .completed(let error):
        if let error = error {
            print("\(service) failed: \(error)")
        } else {
            print("\(service) completed successfully")
        }
    case .inProgress:
        print("\(service) is in progress")
    case .notStarted:
        print("\(service) not started")
    }
}
```

### Error Tracking with Sentry

```swift
// Access Sentry service
let sentry = AppService.sentry

// Log custom errors
sentry.log(customError)

// Set user context
sentry.setUserID("user-123")
```

## 🏗 Architecture

### Service Architecture

The framework follows a modular architecture with clear separation of concerns:

```
AppServices (Main Coordinator)
├── AmplitudeService (Analytics)
├── AppsflyerService (Attribution)
├── FacebookService (Social Integration)
├── RemoteConfigService (Configuration)
├── AttributionService (Custom Attribution)
├── SentryService (Error Tracking)
├── SubscriptionService (In-App Purchases)
└── AttestService (App Integrity)
```

### Key Components

- **[`AppService`](Sources/AppServices/AppServiceMain/AppService.swift)** - Main coordinator actor that manages all services
- **[`AppServiceProtocol`](Sources/AppServices/AppServiceMain/AppServiceProtocol.swift)** - Public interface for the framework
- **Configuration Protocols** - Type-safe configuration system
- **Service Managers** - Individual service implementations
- **Models** - Data structures for offerings, analytics, and attribution

### Concurrency Model

The framework is built with Swift's modern concurrency features:
- All public APIs use `async/await`
- Main coordinator is implemented as an `actor` for thread safety
- Service operations run concurrently where possible
- Network operations are properly isolated

## 📚 Dependencies

The framework integrates the following external dependencies:

- **Firebase iOS SDK** (10.0.0+) - Remote configuration and analytics
- **Facebook iOS SDK** (17.0.0+) - Social features and attribution
- **AppsFlyer Framework** (6.0.0+) - Marketing attribution
- **Amplitude Swift** (1.14.0+) - Analytics and experimentation
- **Amplitude Experiment** (1.13.5+) - A/B testing
- **Sentry Cocoa** (8.35.0+) - Error tracking and performance monitoring

## 🔧 Advanced Configuration

### Custom Remote Config

Implement [`AppRemoteConfigProtocol`](Sources/AppServices/Protocols/RemoteConfig/AppRemoteConfigProtocol.swift) for custom remote configuration:

```swift
struct CustomRemoteConfig: AppRemoteConfigProtocol {
        typealias AppRemoteConfigs = RemoteConfigs
}

enum RemoteConfigs: String, CaseIterable, AppRemoteConfigurable {
        case ab_onboarding
        case minimal_supported_app_version
        
        var key: String { return rawValue }
            
            var defaultValue: String {
            switch self {
            case .minimal_supported_app_version:
                "1.0.0"
            case .ab_onboarding:
                "none"
            }
        }
    
        var stickyBucketed: Bool {
            switch self {
            case .ab_onboarding:
                return false
            default:
                return false
        }
    }
}
```

### Custom Attribution Data

Implement [`AttributionDataProtocol`](Sources/AppServices/Protocols/Analytics/AttributionDataProtocol.swift) for server communication:

```swift
struct AttributionData: AttributionDataProtocol {
    enum AttributionEndpoints: String, AttributionConfigProtocol {
        case installPath: String { return "https://api.yourserver.com/install" }
        case purchasePath: String { return "https://api.yourserver.com/purchase" }
    }
}
```

### Paywall Configuration

Define your subscription offerings using [`AppPaywallDataProtocol`](Sources/AppServices/Protocols/Paywall/AppPaywallDataProtocol.swift):

```swift
class PaywallData: AppPaywallDataProtocol {
    var defaultPaywall: Paywall {
        return Paywall.defaultPaywall
    }
    
    typealias PurchaseGroup = AppPurchaseGroup
    typealias PaywallConfiguration = Paywall
}
```

## 🔒 Privacy & Security

- **ATT Compliance** - Built-in App Tracking Transparency support
- **App Attestation** - iOS App Attest integration for security
- **Data Protection** - Secure handling of user data and attribution information
- **GDPR Ready** - Configurable data collection based on user consent

## 🐛 Debugging

### Service Status Monitoring

Monitor individual service status:

```swift
let statuses = await AppService.appServicesStatus
print("Attribution: \(statuses[.attribution] ?? .notStarted)")
print("Subscriptions: \(statuses[.subscription] ?? .notStarted)")
print("Remote Config: \(statuses[.remoteConfig] ?? .notStarted)")
```

### Logging

The framework provides detailed logging through Sentry integration and console output for debugging.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

**Note**: This framework requires proper configuration of all integrated services (Amplitude, AppsFlyer, Firebase, etc.) with valid API keys and credentials. Ensure you have accounts and API keys for the services you plan to use.
