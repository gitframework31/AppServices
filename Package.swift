// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppServices",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AppServices",
            targets: ["AppServices"]
        ),
        .library(
            name: "AmplitudeService",
            targets: ["AmplitudeService"]
        ),
        .library(
            name: "AppsflyerService",
            targets: ["AppsflyerService"]
        ),
        .library(
            name: "FacebookService",
            targets: ["FacebookService"]
        ),
        .library(
            name: "RemoteConfigService",
            targets: ["RemoteConfigService"]
        ),
        .library(
            name: "AttributionService",
            targets: ["AttributionService"]
        ),
        .library(
            name: "SentryService",
            targets: ["SentryService"]
        ),
        .library(
            name: "SubscriptionService",
            targets: ["SubscriptionService"]
        ),
        .library(
            name: "AttestService",
            targets: ["AttestService"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk", from: "17.0.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Dynamic", from: "6.0.0"),
        .package(url: "https://github.com/amplitude/analytics-connector-ios.git", from: "1.0.0"),
        .package(url: "https://github.com/amplitude/Amplitude-Swift", from: "1.14.0"),
        .package(url: "https://github.com/amplitude/experiment-ios-client", from: "1.13.5"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "9.0.0"),
    ],
    targets: [
        .target(name: "AppServices",
                dependencies: [
                    "AmplitudeService",
                    "AppsflyerService",
                    "FacebookService",
                    "RemoteConfigService",
                    "AttributionService",
                    "SentryService",
                    "SubscriptionService",
                    "AttestService"
                ],
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
               ),
        .target(name: "AmplitudeService",
                dependencies: [
                    .product(name: "AmplitudeSwift", package: "Amplitude-Swift")
                ],
                path: "Sources/AmplitudeService",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
               ),
        .target(name: "AppsflyerService",
                dependencies: [
                    .product(name: "AppsFlyerLib-Dynamic", package: "AppsFlyerFramework-Dynamic")
                ],
                path: "Sources/AppsflyerService",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
               ),
        .target(name: "FacebookService",
                dependencies: [
                    .product(name: "FacebookCore", package: "facebook-ios-sdk")
                ],
                path: "Sources/FacebookService",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
               ),
        .target(name: "RemoteConfigService",
                dependencies: [
                    .product(name: "Experiment", package: "experiment-ios-client"),
                    .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                ],
                path: "Sources/RemoteConfigService",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "AttributionService",
                path: "Sources/AttributionService",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "SentryService",
                dependencies: [
                    .product(name: "Sentry", package: "sentry-cocoa")
                ],
                path: "Sources/SentryService",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
               ),
        .target(name: "SubscriptionService",
                path: "Sources/SubscriptionService",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "AttestService",
                path: "Sources/AttestService",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
    ]
)
