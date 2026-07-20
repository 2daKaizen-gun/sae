// swift-tools-version: 6.0
import PackageDescription

// SaeTiming — PVT 반응시간 측정의 순수 코어 (헌법 제1조: 정확도 엔진).
//
// UIKit/SwiftUI 없이 타이밍 수학·분류·ISI 스케줄만 담는다. 플랫폼 독립이라
// `swift test`로 시뮬레이터 없이 정확도를 증명할 수 있다(timing-engine §8-1).
// iOS 앱은 이 로컬 패키지를 의존으로 물어 측정 계층과 표현 계층을 분리한다(timing-engine §6).
let package = Package(
    name: "SaeTiming",
    platforms: [
        .iOS(.v17),   // tech-stack: 최소 iOS 17
        .macOS(.v14), // swift test를 macOS에서 돌리기 위한 호스트 플랫폼
    ],
    products: [
        .library(name: "SaeTiming", targets: ["SaeTiming"]),
    ],
    targets: [
        .target(name: "SaeTiming"),
        .testTarget(name: "SaeTimingTests", dependencies: ["SaeTiming"]),
    ]
)
