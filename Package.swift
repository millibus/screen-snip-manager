// swift-tools-version: 5.9
import PackageDescription

// Only the mocked Gemini service: no app startup, preferences, clipboard or dependencies.
let package = Package(
    name: "GeminiServiceRegression",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ClipboardManager", path: "ClipboardManager/Services",
                exclude: ["ClipboardStore.swift", "FuzzySearchService.swift", "HotKeyService.swift",
                          "PasteboardWatcher.swift", "SensitiveDataDetector.swift", "UserDefaultsKeys.swift"],
                sources: ["GeminiService.swift"]),
        .testTarget(name: "GeminiServiceTests", dependencies: ["ClipboardManager"],
                    path: "ClipboardManagerTests",
                    exclude: ["ClipboardStoreTests.swift", "ClipboardEntryTests.swift",
                              "FuzzySearchServiceTests.swift", "SensitiveDataDetectorTests.swift"],
                    sources: ["GeminiServiceTests.swift"])
    ]
)
