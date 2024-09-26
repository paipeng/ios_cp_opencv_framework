//
//  Package.swift
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

import Foundation
// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "CPOpenCV",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CPOpenCV",
            targets: ["CPOpenCV"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CPOpenCV",
            exclude: ["instructions.md"],
            resources: [
                .process("text.txt"),
                .process("example.png"),
                .copy("settings.plist")
            ]
        )
        .testTarget(
            name: "CPOpenCVTests",
            dependencies: ["CPOpenCV"]),
    ]
)
