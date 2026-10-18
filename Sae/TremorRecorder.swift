import Foundation
import CoreMotion
import SwiftData
import SaeTiming

/// 손떨림 기록 — CoreMotion 가속도를 10초 모아 순수 `TremorAnalysis`에 넘기고, 결과를 저장한다.
///
/// ## 언제 부르나
/// PVT 세션이 **끝난 뒤** 결과 화면에서만, 사용자가 시작했을 때만 부른다. 타이밍 루프와 겹치지 않는다(제1조 1항).
///
/// ## 권한
/// `CMMotionManager`의 가속도는 권한 요청이 필요 없다(활동·걸음 수 API와 다르다). 그래도 무엇을 재는지는
/// 화면이 먼저 말한다(제3조 3항). 데이터는 기기 안에만 남는다.
///
/// ## 표본률은 실측한다
/// 50 Hz를 요청해도 실제 간격은 흔들릴 수 있다. 분석에는 요청값이 아니라 **받은 표본의 타임스탬프로 잰 표본률**을
/// 넘긴다 — 틀린 표본률은 주파수를 그대로 틀리게 만든다.
@MainActor
enum TremorRecorder {
    enum Outcome: Equatable {
        /// 이 기기에 모션 센서가 없다(예: 시뮬레이터).
        case unavailable
        /// 기록은 했지만 분석에 쓸 수 없었다(너무 짧거나 표본률 부족).
        case unusable
        /// 분석·저장까지 끝났다.
        case reading(TremorResult)
    }

    /// 기록 길이(초). score-algorithm §3-1 — 앞뒤 1초를 버리면 8초가 분석된다.
    static let recordingSeconds = 10.0
    /// 요청 표본률(Hz) — Santos et al. 2022와 같은 50 Hz.
    static let requestedRateHz = 50.0
    /// CoreMotion은 g 단위를 준다. m/s²로 바꾼다(표준 중력).
    private static let standardGravity = 9.80665

    /// 앱 전체에서 한 개만 쓴다(애플 권장).
    private static let manager = CMMotionManager()

    static var isAvailable: Bool { manager.isDeviceMotionAvailable }

    /// 10초 기록하고 분석해 저장한다. `progress`는 0~1(화면 표시용).
    static func record(in context: ModelContext, progress: @escaping (Double) -> Void) async throws -> Outcome {
        guard manager.isDeviceMotionAvailable else { return .unavailable }

        let startedAt = Date()
        var samples: [AccelerationSample] = []
        var timestamps: [TimeInterval] = []

        manager.deviceMotionUpdateInterval = 1 / requestedRateHz
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let a = motion.userAcceleration
            samples.append(AccelerationSample(
                x: a.x * standardGravity, y: a.y * standardGravity, z: a.z * standardGravity
            ))
            timestamps.append(motion.timestamp)
            if let first = timestamps.first {
                progress(min(1, (motion.timestamp - first) / recordingSeconds))
            }
        }
        defer { manager.stopDeviceMotionUpdates() }

        try await Task.sleep(for: .seconds(recordingSeconds))
        manager.stopDeviceMotionUpdates()

        guard let first = timestamps.first, let last = timestamps.last, timestamps.count > 1, last > first else {
            return .unusable
        }
        let measuredRate = Double(timestamps.count - 1) / (last - first)
        guard let result = TremorAnalysis.analyze(samples, sampleRateHz: measuredRate) else { return .unusable }

        context.insert(TremorReading(
            measuredAt: startedAt,
            durationMs: Int(((last - first) * 1_000).rounded()),
            sampleRateHz: measuredRate,
            bandRMS: result.bandRMS,
            peakFrequencyHz: result.peakFrequencyHz,
            deviceModel: deviceModelIdentifier
        ))
        try context.save()
        return .reading(result)
    }

    /// 기종 식별자(예: `iPhone17,1`) — 같은 기기끼리만 비교하기 위한 키(data-model `TremorReading`).
    static var deviceModelIdentifier: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
