// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "McccAlarm",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "McccAlarm",
            targets: ["McccAlarm"]
        ),
    ],
    targets: [
        .target(
            name: "McccAlarm",
            path: "McccAlarm",
            sources: ["Classes"],
            publicHeadersPath: nil
        ),
    ]
)
