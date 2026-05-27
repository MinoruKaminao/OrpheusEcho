// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LostPetNameFinder",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LostPetNameFinder",
            targets: ["LostPetNameFinder"]
        ),
    ],
    targets: [
        .target(
            name: "LostPetNameFinder",
            dependencies: [],
            exclude: ["LostPetNameFinderApp.swift"]
        ),
        .executableTarget(
            name: "LostPetNameFinderTestRunner",
            dependencies: ["LostPetNameFinder"],
            path: "Sources/TestRunner"
        )
    ]
)
