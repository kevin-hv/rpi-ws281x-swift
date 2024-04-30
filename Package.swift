// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var rpiSwiftDependencies : [Target.Dependency] = []

#if os(Linux)
rpiSwiftDependencies.append("rpi-ws281x")
#endif

let package = Package(name: "rpi-ws281x-swift",
  products: [
    .library(name: "rpi-ws281x-swift", targets: ["rpi-ws281x-swift"]),
  ],
  dependencies: [],
  targets: [
    .target(
        name: "rpi-ws281x-swift",
        dependencies: rpiSwiftDependencies,
        path: "Sources/rpi-ws281x-swift"
    ),
    .target(name: "rpi-ws281x", path: "Sources/rpi-ws281x")
  ]
)
