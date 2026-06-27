// swift-tools-version: 6.2
// A self-contained, app-independent SwiftUI viewer for the current process's
// OSLogStore.

import PackageDescription

let package = Package(
    name: "OSLogViewer",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(name: "OSLogViewer", targets: ["OSLogViewer"])
    ],
    targets: [
        .target(
            name: "OSLogViewer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
