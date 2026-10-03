import SaeTiming

/// 톤 밴드 — さえちゃん 대사의 **말투와 행동 제안만** 고른다(character-voice §4).
///
/// 화면에 라벨로 보이지 않는다. 경계값 80/60/40/20에는 출처가 없어서(열린 결정), 사용자에게
/// "당신은 피곤하다" 같은 분류를 내보이지 않고 문장의 결만 바꾸는 데 쓴다(제2조). 케이스 이름은
/// 사람의 상태가 아니라 **측정이 어땠는가**를 가리키는 내부 이름이다.
public enum ToneBand: String, CaseIterable, Sendable {
    case sharp, steady, dull, slow, low

    /// 각 밴드의 하한(포함). **임시값, 출처 없음** — 실데이터로 튜닝할 열린 결정.
    public static let provisionalLowerBounds: [(band: ToneBand, from: Int)] = [
        (.sharp, 80), (.steady, 60), (.dull, 40), (.slow, 20), (.low, 0),
    ]

    /// 冴え度(0~100)가 속한 밴드. 범위 밖 값은 가장 가까운 끝 밴드로 본다.
    public init(score: Int) {
        self = Self.provisionalLowerBounds.first { score >= $0.from }?.band ?? .low
    }
}

/// さえちゃん 대사 한 줄 — **어떤 문장을 쓸지**와 **그 문장에 박을 사실**.
///
/// 문장 자체는 String Catalog(`catalogKey`)에 있다(제5조). 여기서 정하는 건 종류·변주·사실뿐이라
/// 언어와 무관하게 테스트할 수 있다.
public struct VoiceLine: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// 점수가 난 세션 — 밴드가 말투를 고른다.
        case scored(ToneBand)
        /// 첫 유효 측정 — 비교할 과거가 없으니 판단을 자제하고 측정의 의미를 말한다(§7).
        case firstMeasurement
        /// 무효 세션 — 숫자 없이 재시도를 권한다(§7, 제2조).
        case invalidSession
    }

    /// ① 사실 — 엔진이 낸 숫자 그대로. 대사는 이 값을 반올림·미화하지 않는다(제4조 1항).
    public struct Facts: Equatable, Sendable {
        public let score: Int
        public let lapseCount: Int

        public init(score: Int, lapseCount: Int) {
            self.score = score
            self.lapseCount = lapseCount
        }

        /// 엔진의 산출물에서 바로 만든다 — 사실이 다른 경로로 새어 들어오지 않게.
        public init(_ sae: SaeScore) {
            self.init(score: sae.score, lapseCount: sae.evidence.lapseCount)
        }
    }

    public let kind: Kind
    /// 같은 종류 안의 변주 번호(0부터). 반복 피로를 줄이려고 돌려 쓴다(§8).
    public let variant: Int
    /// 문장에 박을 사실. 무효 세션이면 `nil` — 숫자가 없는 날에 숫자를 만들지 않는다.
    public let facts: Facts?

    /// String Catalog 키 — `voice.<종류>.<변주>`.
    public var catalogKey: String {
        let name: String
        switch kind {
        case .scored(let band): name = band.rawValue
        case .firstMeasurement: name = "first"
        case .invalidSession: name = "invalid"
        }
        return "voice.\(name).\(variant)"
    }
}

/// 대사 선택 — "점수 + 상황 → 문장"의 단순 매핑(§8, 제7조: 대화 엔진을 만들지 않는다).
///
/// 단방향이다: 엔진의 결과를 읽기만 하고 아무것도 되돌려 쓰지 않는다(§1).
public enum SaeVoice {
    /// 종류별 변주 수. 밴드·무효는 2개씩 돌리고, 첫 측정은 한 번뿐이라 1개.
    public static func variantCount(for kind: VoiceLine.Kind) -> Int {
        switch kind {
        case .scored, .invalidSession: return 2
        case .firstMeasurement: return 1
        }
    }

    /// 한 세션의 대사를 고른다.
    ///
    /// - Parameters:
    ///   - facts: 점수가 났으면 그 사실, 무효 세션이면 `nil`.
    ///   - isFirstMeasurement: 이 사용자의 첫 유효 측정인가.
    ///   - rotation: 변주를 고르는 수(앱은 날짜에서 만든다 — 같은 날엔 같은 문장). 음수도 받는다.
    public static func line(facts: VoiceLine.Facts?, isFirstMeasurement: Bool, rotation: Int) -> VoiceLine {
        let kind: VoiceLine.Kind
        if let facts {
            kind = isFirstMeasurement ? .firstMeasurement : .scored(ToneBand(score: facts.score))
        } else {
            kind = .invalidSession
        }
        let count = variantCount(for: kind)
        let variant = ((rotation % count) + count) % count
        return VoiceLine(kind: kind, variant: variant, facts: facts)
    }

    /// 앱이 카탈로그에 갖춰야 할 키 전체 — 테스트가 이 목록으로 빠짐을 막는다.
    public static var allCatalogKeys: [String] {
        let kinds: [VoiceLine.Kind] = ToneBand.allCases.map { .scored($0) } + [.firstMeasurement, .invalidSession]
        return kinds.flatMap { kind in
            (0..<variantCount(for: kind)).map { VoiceLine(kind: kind, variant: $0, facts: nil).catalogKey }
        }
    }
}
