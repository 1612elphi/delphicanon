// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DelphiCanon",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "DelphiCanon", targets: ["DelphiCanon"]),
    ],
    targets: [
        .target(
            name: "DelphiCanon",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
