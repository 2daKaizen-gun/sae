import Foundation

/// 가속도 표본 하나(m/s²) — 중력을 뺀 사용자 가속도(CoreMotion `userAcceleration`을 m/s²로 바꾼 값).
public struct AccelerationSample: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// 손떨림 분석 결과 — **같은 기기 안에서만** 비교할 수 있는 참고 지표다.
public struct TremorResult: Equatable, Sendable {
    /// 5~12 Hz 대역 가속도의 RMS(m/s², 세 축 합산).
    public let bandRMS: Double
    /// 5~12 Hz 안에서 파워가 가장 큰 주파수(Hz).
    public let peakFrequencyHz: Double
    /// 분석에 쓴 구간 길이(초) — 앞뒤를 잘라낸 뒤.
    public let analyzedSeconds: Double
}

/// 생리적 손떨림 분석 — 순수 함수(score-algorithm §3).
///
/// ## 방법과 출처
/// Santos et al. (2022), *Scientific Reports* 12, DOI 10.1038/s41598-022-21310-4 의 스마트폰 방식을 따른다:
/// 선형 추세 제거, **5–12 Hz 대역** 분석, 50 Hz 표본. 같은 논문은 기기 질량이 스펙트럼을 바꾼다고 보고하므로
/// 값은 **같은 기기 안에서만** 비교한다(제2조 3항).
///
/// ## 이 앱의 선택(출처가 아니라 판단)
/// - 진폭은 논문의 FFT 정점 진폭(단위 미기재) 대신 **대역 RMS(m/s²)** — 단위가 있어 설명할 수 있다.
/// - 10초 기록에서 **앞뒤 1초씩** 잘라낸다(손을 대는 순간·떼는 순간). 논문은 60초에서 5초씩.
/// - 분석 구간이 **6초 미만**이거나 표본률이 12 Hz를 담지 못하면(나이퀴스트 24 Hz 이하) 결과를 내지 않는다.
///
/// DFT를 직접 계산한다 — 표본 수백 개라 O(n²)로 충분하고, DSP 의존성을 들이지 않는다(제7조).
public enum TremorAnalysis {
    /// 분석 대역(Hz) — Santos et al. 2022.
    public static let band: ClosedRange<Double> = 5...12
    /// 앞뒤에서 잘라낼 시간(초). 이 앱의 선택.
    public static let edgeTrimSeconds = 1.0
    /// 결과를 내기 위한 최소 분석 구간(초). 이 앱의 선택 — 6초면 0.17 Hz 해상도.
    public static let minimumAnalyzedSeconds = 6.0

    /// 표본에서 손떨림을 분석한다. 쓸 수 없는 기록이면 `nil` — 숫자를 지어내지 않는다.
    public static func analyze(_ samples: [AccelerationSample], sampleRateHz: Double) -> TremorResult? {
        guard sampleRateHz > 2 * band.upperBound else { return nil }

        let trim = Int((edgeTrimSeconds * sampleRateHz).rounded())
        guard samples.count > 2 * trim else { return nil }
        let window = Array(samples[trim..<(samples.count - trim)])
        let n = window.count
        let seconds = Double(n) / sampleRateHz
        guard seconds >= minimumAnalyzedSeconds else { return nil }

        let axes = [window.map(\.x), window.map(\.y), window.map(\.z)].map(detrended)

        // 한쪽 스펙트럼의 각 빈 파워(평균제곱 기여분)를 세 축에 걸쳐 더한다.
        // 파스발: mean(x²) = Σ_k |X_k|² / n². 0 < k < n/2 인 빈은 대칭 짝까지 2배.
        var bandPower = 0.0
        var peak: (frequency: Double, power: Double) = (0, -1)
        for k in 1..<((n + 1) / 2) {
            let frequency = Double(k) * sampleRateHz / Double(n)
            guard band.contains(frequency) else { continue }
            let power = axes.reduce(0.0) { $0 + 2 * magnitudeSquared(of: $1, bin: k) / Double(n * n) }
            bandPower += power
            if power > peak.power { peak = (frequency, power) }
        }
        guard peak.power >= 0 else { return nil }
        return TremorResult(bandRMS: bandPower.squareRoot(), peakFrequencyHz: peak.frequency, analyzedSeconds: seconds)
    }

    /// 최소제곱 직선을 빼서 오프셋과 느린 흐름(드리프트)을 없앤다.
    static func detrended(_ values: [Double]) -> [Double] {
        let n = Double(values.count)
        let meanT = (n - 1) / 2
        let meanV = values.reduce(0, +) / n
        var covariance = 0.0
        var variance = 0.0
        for (t, v) in values.enumerated() {
            covariance += (Double(t) - meanT) * (v - meanV)
            variance += (Double(t) - meanT) * (Double(t) - meanT)
        }
        let slope = variance > 0 ? covariance / variance : 0
        return values.enumerated().map { t, v in v - (meanV + slope * (Double(t) - meanT)) }
    }

    /// DFT 한 빈의 |X_k|².
    static func magnitudeSquared(of values: [Double], bin k: Int) -> Double {
        let n = Double(values.count)
        var re = 0.0
        var im = 0.0
        for (t, v) in values.enumerated() {
            let angle = -2 * Double.pi * Double(k) * Double(t) / n
            re += v * cos(angle)
            im += v * sin(angle)
        }
        return re * re + im * im
    }
}
