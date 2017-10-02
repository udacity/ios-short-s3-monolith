// swift-tools-version:3.1
import PackageDescription

let package = Package(
    name: "monolith",
    targets: [
        Target(name: "monolith")
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/Kitura-Credentials.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Kitura-CredentialsHTTP.git", majorVersion: 1),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-Crypto.git", majorVersion: 1)
    ]
)
