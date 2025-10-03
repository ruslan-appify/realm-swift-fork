// swift-tools-version:5.7

import PackageDescription
import Foundation

let coreVersion = Version("13.26.0")
let cocoaVersion = Version("10.48.1")

let cxxSettings: [CXXSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .define("REALM_SPM", to: "1"),
    .define("REALM_ENABLE_SYNC", to: "1"),
    .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersion)\""),
    .define("REALM_VERSION", to: "\"\(coreVersion)\""),
    .define("REALM_IOPLATFORMUUID", to: "@\"\(runCommand())\""),

    .define("REALM_DEBUG", .when(configuration: .debug)),
    .define("REALM_NO_CONFIG"),
    .define("REALM_INSTALL_LIBEXECDIR", to: ""),
    .define("REALM_ENABLE_ASSERTIONS", to: "1"),
    .define("REALM_ENABLE_ENCRYPTION", to: "1"),

    .define("REALM_VERSION_MAJOR", to: String(coreVersion.major)),
    .define("REALM_VERSION_MINOR", to: String(coreVersion.minor)),
    .define("REALM_VERSION_PATCH", to: String(coreVersion.patch)),
    .define("REALM_VERSION_EXTRA", to: "\"\(coreVersion.prereleaseIdentifiers.first ?? "")\""),
    .define("REALM_VERSION_STRING", to: "\"\(coreVersion)\""),
    .define("REALM_ENABLE_GEOSPATIAL", to: "1"),
]
let testCxxSettings: [CXXSetting] = cxxSettings + [
    // Command-line `swift build` resolves header search paths
    // relative to the package root, while Xcode resolves them
    // relative to the target root, so we need both.
    .headerSearchPath("RealmFork"),
    .headerSearchPath(".."),
]

// SPM requires all targets to explicitly include or exclude every file, which
// gets very awkward when we have four targets building from a single directory
let objectServerTestSources = [
    "AsyncSyncTests.swift",
    "ClientResetTests.swift",
    "CombineSyncTests.swift",
    "EventTests.swift",
    "Object-Server-Tests-Bridging-Header.h",
    "ObjectServerTests-Info.plist",
    "RLMAsymmetricSyncServerTests.mm",
    "RLMBSONTests.mm",
    "RLMCollectionSyncTests.mm",
    "RLMFlexibleSyncServerTests.mm",
    "RLMMongoClientTests.mm",
    "RLMObjectServerPartitionTests.mm",
    "RLMObjectServerTests.mm",
    "RLMServerTestObjects.h",
    "RLMServerTestObjects.m",
    "RLMSubscriptionTests.mm",
    "RLMSyncTestCase.h",
    "RLMSyncTestCase.mm",
    "RLMUser+ObjectServerTests.h",
    "RLMUser+ObjectServerTests.mm",
    "RLMWatchTestUtility.h",
    "RLMWatchTestUtility.m",
    "RealmServer.swift",
    "SwiftAsymmetricSyncServerTests.swift",
    "SwiftCollectionSyncTests.swift",
    "SwiftFlexibleSyncServerTests.swift",
    "SwiftMongoClientTests.swift",
    "SwiftObjectServerPartitionTests.swift",
    "SwiftObjectServerTests.swift",
    "SwiftServerObjects.swift",
    "SwiftSyncTestCase.swift",
    "SwiftUIServerTests.swift",
    "TimeoutProxyServer.swift",
    "WatchTestUtility.swift",
    "certificates",
    "config_overrides.json",
    "include",
    "setup_baas.rb",
]

func objectServerTestSupportTarget(name: String, dependencies: [Target.Dependency], sources: [String]) -> Target {
    .target(
        name: name,
        dependencies: dependencies,
        path: "RealmFork/ObjectServerTests",
        exclude: objectServerTestSources.filter { !sources.contains($0) },
        sources: sources,
        cxxSettings: testCxxSettings
    )
}

func objectServerTestTarget(name: String, sources: [String]) -> Target {
    .testTarget(
        name: name,
        dependencies: ["RealmSwiftFork", "RealmTestSupportFork", "RealmSyncTestSupportFork", "RealmSwiftSyncTestSupportFork"],
        path: "RealmFork/ObjectServerTests",
        exclude: objectServerTestSources.filter { !sources.contains($0) },
        sources: sources,
        cxxSettings: testCxxSettings
    )
}

func runCommand() -> String {
    let task = Process()
    let pipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioregg")
    task.arguments = ["-rd1", "-c", "IOPlatformExpertDevice"]
    task.standardInput = nil
    task.standardError = nil
    task.standardOutput = pipe
    do {
        try task.run()
    } catch {
        return ""
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    let range = NSRange(output.startIndex..., in: output)
    guard let regex = try? NSRegularExpression(pattern: ".*\\\"IOPlatformUUID\\\"\\s=\\s\\\"(.+)\\\"", options: .caseInsensitive),
          let firstMatch = regex.matches(in: output, range: range).first else {
        return ""
    }

    let matches = (0..<firstMatch.numberOfRanges).compactMap { ind -> String? in
        let matchRange = firstMatch.range(at: ind)
        if matchRange != range,
           let substringRange = Range(matchRange, in: output) {
            let capture = String(output[substringRange])
            return capture
        }
        return nil
    }
    return matches.last ?? ""
}

let package = Package(
    name: "RealmFork",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "RealmFork",
            targets: ["RealmFork"]),
        .library(
            name: "RealmSwiftFork",
            targets: ["RealmFork", "RealmSwiftFork"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ruslan-appify/realm-core-fork.git", branch: "master")
    ],
    targets: [
      .target(
            name: "RealmFork",
            dependencies: [.product(name: "RealmCoreFork", package: "realm-core-fork")],
            path: ".",
            exclude: [
                "CHANGELOG.md",
                "CONTRIBUTING.md",
                "Carthage",
                "Configuration",
                "LICENSE",
                "Package.swift",
                "README.md",
                "Realm.podspec",
                "RealmFork.xcodeproj",
                "RealmFork/ObjectServerTests",
                "RealmFork/Realm-Info.plist",
                "RealmFork/Swift/RLMSupport.swift",
                "RealmFork/TestUtils",
                "RealmFork/Tests",
                "RealmSwiftFork",
                "RealmSwift.podspec",
                "SUPPORT.md",
                "build.sh",
                "ci_scripts/ci_post_clone.sh",
                "contrib",
                "dependencies.list",
                "docs",
                "examples",
                "include",
                "logo.png",
                "plugin",
                "scripts",
            ],
            sources: [
                "RealmFork/RLMAccessor.mm",
                "RealmFork/RLMAnalytics.mm",
                "RealmFork/RLMArray.mm",
                "RealmFork/RLMAsymmetricObject.mm",
                "RealmFork/RLMAsyncTask.mm",
                "RealmFork/RLMClassInfo.mm",
                "RealmFork/RLMCollection.mm",
                "RealmFork/RLMConstants.m",
                "RealmFork/RLMDecimal128.mm",
                "RealmFork/RLMDictionary.mm",
                "RealmFork/RLMEmbeddedObject.mm",
                "RealmFork/RLMError.mm",
                "RealmFork/RLMEvent.mm",
                "RealmFork/RLMGeospatial.mm",
                "RealmFork/RLMLogger.mm",
                "RealmFork/RLMManagedArray.mm",
                "RealmFork/RLMManagedDictionary.mm",
                "RealmFork/RLMManagedSet.mm",
                "RealmFork/RLMMigration.mm",
                "RealmFork/RLMObject.mm",
                "RealmFork/RLMObjectBase.mm",
                "RealmFork/RLMObjectId.mm",
                "RealmFork/RLMObjectSchema.mm",
                "RealmFork/RLMObjectStore.mm",
                "RealmFork/RLMObservation.mm",
                "RealmFork/RLMPredicateUtil.mm",
                "RealmFork/RLMProperty.mm",
                "RealmFork/RLMQueryUtil.mm",
                "RealmFork/RLMRealm.mm",
                "RealmFork/RLMRealmConfiguration.mm",
                "RealmFork/RLMRealmUtil.mm",
                "RealmFork/RLMResults.mm",
                "RealmFork/RLMScheduler.mm",
                "RealmFork/RLMSchema.mm",
                "RealmFork/RLMSectionedResults.mm",
                "RealmFork/RLMSet.mm",
                "RealmFork/RLMSwiftCollectionBase.mm",
                "RealmFork/RLMSwiftSupport.m",
                "RealmFork/RLMSwiftValueStorage.mm",
                "RealmFork/RLMThreadSafeReference.mm",
                "RealmFork/RLMUUID.mm",
                "RealmFork/RLMUpdateChecker.mm",
                "RealmFork/RLMUtil.mm",
                "RealmFork/RLMValue.mm",

                // Sync source files
                "RealmFork/NSError+RLMSync.m",
                "RealmFork/RLMApp.mm",
                "RealmFork/RLMAPIKeyAuth.mm",
                "RealmFork/RLMBSON.mm",
                "RealmFork/RLMCredentials.mm",
                "RealmFork/RLMEmailPasswordAuth.mm",
                "RealmFork/RLMFindOneAndModifyOptions.mm",
                "RealmFork/RLMFindOptions.mm",
                "RealmFork/RLMMongoClient.mm",
                "RealmFork/RLMMongoCollection.mm",
                "RealmFork/RLMNetworkTransport.mm",
                "RealmFork/RLMProviderClient.mm",
                "RealmFork/RLMPushClient.mm",
                "RealmFork/RLMRealm+Sync.mm",
                "RealmFork/RLMSyncConfiguration.mm",
                "RealmFork/RLMSyncManager.mm",
                "RealmFork/RLMSyncSession.mm",
                "RealmFork/RLMSyncSubscription.mm",
                "RealmFork/RLMSyncUtil.mm",
                "RealmFork/RLMUpdateResult.mm",
                "RealmFork/RLMUser.mm",
                "RealmFork/RLMUserAPIKey.mm"
            ],
            resources: [
                .copy("RealmFork/PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "include",
            cxxSettings: cxxSettings,
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS, .macCatalyst, .tvOS, .watchOS]))
            ]
        ),
        .target(
            name: "RealmSwiftFork",
            dependencies: ["RealmFork"],
            path: "RealmSwiftFork",
            exclude: [
                "Nonsync.swift",
                "RealmSwift-Info.plist",
                "Tests",
            ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "RealmTestSupportFork",
            dependencies: ["RealmFork"],
            path: "RealmFork/TestUtils",
            cxxSettings: testCxxSettings
        ),
        .target(
            name: "RealmSwiftTestSupportFork",
            dependencies: ["RealmSwiftFork", "RealmTestSupportFork"],
            path: "RealmSwiftFork/Tests",
            sources: ["TestUtils.swift"]
        ),
        .testTarget(
            name: "RealmTestsFork",
            dependencies: ["RealmFork", "RealmTestSupportFork"],
            path: "RealmFork/Tests",
            exclude: [
                "PrimitiveArrayPropertyTests.tpl.m",
                "PrimitiveDictionaryPropertyTests.tpl.m",
                "PrimitiveRLMValuePropertyTests.tpl.m",
                "PrimitiveSetPropertyTests.tpl.m",
                "RealmTests-Info.plist",
                "Swift",
                "SwiftUITestHost",
                "SwiftUITestHostUITests",
                "TestHost",
                "array_tests.py",
                "dictionary_tests.py",
                "fileformat-pre-null.realm",
                "mixed_tests.py",
                "set_tests.py",
                "SwiftUISyncTestHost",
                "SwiftUISyncTestHostUITests"
            ],
            cxxSettings: testCxxSettings
        ),
        .testTarget(
            name: "RealmObjcSwiftTestsFork",
            dependencies: ["RealmFork", "RealmTestSupportFork"],
            path: "RealmFork/Tests/Swift",
            exclude: ["RealmObjcSwiftTests-Info.plist"]
        ),
        .testTarget(
            name: "RealmSwiftTestsFork",
            dependencies: ["RealmSwiftFork", "RealmTestSupportFork", "RealmSwiftTestSupportFork"],
            path: "RealmSwiftFork/Tests",
            exclude: [
                "RealmSwiftTests-Info.plist",
                "QueryTests.swift.gyb",
                "TestUtils.swift"
            ]
        ),

        // Object server tests have support code written in both obj-c and
        // Swift which is used by both the obj-c and swift test code. SPM
        // doesn't support mixed targets, so this ends up requiring four
        // different targets.
        objectServerTestSupportTarget(
            name: "RealmSyncTestSupportFork",
            dependencies: ["RealmFork", "RealmSwiftFork", "RealmTestSupportFork"],
            sources: [
                "RLMServerTestObjects.m",
                "RLMSyncTestCase.mm",
                "RLMUser+ObjectServerTests.mm",
                "RLMWatchTestUtility.m",
            ]
        ),
        objectServerTestSupportTarget(
            name: "RealmSwiftSyncTestSupportFork",
            dependencies: ["RealmSwiftFork", "RealmTestSupportFork", "RealmSyncTestSupportFork", "RealmSwiftTestSupportFork"],
            sources: [
                 "RealmServer.swift",
                 "SwiftServerObjects.swift",
                 "SwiftSyncTestCase.swift",
                 "TimeoutProxyServer.swift",
                 "WatchTestUtility.swift",
            ]
        ),
        objectServerTestTarget(
            name: "SwiftObjectServerTestsFork",
            sources: [
                "AsyncSyncTests.swift",
                "ClientResetTests.swift",
                "CombineSyncTests.swift",
                "EventTests.swift",
                "SwiftAsymmetricSyncServerTests.swift",
                "SwiftCollectionSyncTests.swift",
                "SwiftFlexibleSyncServerTests.swift",
                "SwiftMongoClientTests.swift",
                "SwiftObjectServerPartitionTests.swift",
                "SwiftObjectServerTests.swift",
                "SwiftUIServerTests.swift",
            ]
        ),
        objectServerTestTarget(
            name: "ObjcObjectServerTestsFork",
            sources: [
                "RLMAsymmetricSyncServerTests.mm",
                "RLMBSONTests.mm",
                "RLMCollectionSyncTests.mm",
                "RLMFlexibleSyncServerTests.mm",
                "RLMMongoClientTests.mm",
                "RLMObjectServerPartitionTests.mm",
                "RLMObjectServerTests.mm",
                "RLMSubscriptionTests.mm",
            ]
        )
    ],
    cxxLanguageStandard: .cxx20
)
