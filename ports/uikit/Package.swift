// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DelphiCanon",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DelphiCanon", targets: ["DelphiCanon"]),
    ],
    dependencies: [
        .package(path: "../../../delphitools-core"),
    ],
    targets: [
        .target(
            name: "DelphiCanon",
            dependencies: [.product(name: "DelphiCore", package: "delphitools-core")],
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
