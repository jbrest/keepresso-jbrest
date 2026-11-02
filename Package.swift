// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeepressoCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "KeepressoCore", targets: ["KeepressoCore"]),
        .library(name: "RuleModel", targets: ["RuleModel"]),
        .library(name: "RuleEvaluation", targets: ["RuleEvaluation"]),
        .library(name: "SystemObservations", targets: ["SystemObservations"]),
        // The caffeinate-style CLI. Built here for the dev loop; the release
        // app embeds the identically sourced `keepresso-cli` Xcode target.
        .executable(name: "keepresso", targets: ["keepresso-cli"]),
        // The privileged helper daemon (an SMAppService LaunchDaemon). Same
        // arrangement: built here for the dev loop, shipped via the
        // identically sourced `keepresso-helper` Xcode target.
        .executable(name: "keepresso-helper", targets: ["keepresso-helper"]),
        // The MCP stdio server exposing automation leases to AI agents. Same
        // arrangement again: dev loop here, embedded Xcode target in releases.
        .executable(name: "keepresso-mcp", targets: ["keepresso-mcp"])
    ],
    targets: [
        .target(name: "RuleModel", path: "Sources/Shared/RuleModel"),
        .target(
            name: "RuleEvaluation",
            dependencies: ["RuleModel"],
            path: "Sources/Shared/RuleEvaluation"
        ),
        .target(
            name: "SystemObservations",
            dependencies: ["RuleModel"],
            path: "Sources/Shared/SystemObservations"
        ),
        .target(
            name: "KeepressoCore",
            dependencies: ["RuleModel", "RuleEvaluation", "SystemObservations"],
            path: "Sources/KeepressoCore"
        ),
        .executableTarget(
            name: "keepresso-cli",
            dependencies: ["KeepressoCore"],
            path: "Sources/keepresso-cli"
        ),
        .executableTarget(
            name: "keepresso-helper",
            dependencies: ["KeepressoCore"],
            path: "Sources/keepresso-helper",
            exclude: ["Info.plist"]
        ),
        .executableTarget(
            name: "keepresso-mcp",
            dependencies: ["KeepressoCore"],
            path: "Sources/keepresso-mcp"
        ),
        .testTarget(
            name: "RuleModelTests",
            dependencies: ["RuleModel"],
            path: "Tests/Shared/RuleModelTests"
        ),
        .testTarget(
            name: "RuleEvaluationTests",
            dependencies: ["RuleEvaluation"],
            path: "Tests/Shared/RuleEvaluationTests"
        ),
        .testTarget(
            name: "KeepressoCoreTests",
            dependencies: ["KeepressoCore"],
            path: "Tests/KeepressoCoreTests"
        )
    ]
)
