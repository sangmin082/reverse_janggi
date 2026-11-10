// swift-tools-version:5.9
// 규칙 엔진 + AI만 묶은 패키지. 앱(Xcode 프로젝트)과 같은 소스를 쓰며,
// macOS/Linux 어디서든 `swift test`로 규칙을 검증할 수 있게 한다.
import PackageDescription

let package = Package(
    name: "JanggiEngine",
    targets: [
        .target(
            name: "JanggiEngine",
            path: "ReverseJanggi",
            exclude: [
                "App", "Views", "Online", "Assets.xcassets",
                "Info.plist", "PrivacyInfo.xcprivacy", "InfoPlist.xcstrings", "Localizable.xcstrings",
            ],
            sources: ["Engine", "AI"]
        ),
        .testTarget(
            name: "JanggiEngineTests",
            dependencies: ["JanggiEngine"],
            path: "Tests/JanggiEngineTests"
        ),
    ]
)
