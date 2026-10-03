import SwiftUI
import SwiftData
import SaeTiming
import SaeVoice

/// さえちゃん 한마디 — 결과 위에 얹는 **전달 계층**(제4조).
///
/// 어떤 문장을 쓸지는 `SaeVoice`가 정하고(테스트로 증명됨), 여기서는 그 문장을 String Catalog에서
/// 꺼내 **엔진의 숫자를 그대로** 끼워 넣기만 한다. 이 카드를 지워도 결과 화면의 숫자는 그대로 성립한다
/// (character-voice §1 — 분리된 계층).
struct VoiceCard: View {
    let result: PVTSessionResult

    @Query private var sessions: [PVTSession]
    @Query private var scores: [DailyScore]

    var body: some View {
        SaeCard {
            Text("voice.name")
                .font(SaeTheme.Typography.cardTitle)
                .foregroundStyle(SaeTheme.Palette.brand)
            Text(Self.text(for: line))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var line: VoiceLine {
        let facts = SaeScorer.score(from: result.summary, validity: result.validity).map(VoiceLine.Facts.init)
        return SaeVoice.line(facts: facts, isFirstMeasurement: isFirstMeasurement, rotation: rotation)
    }

    /// 이 세션 전에 유효한 측정이 한 번도 없었는가.
    ///
    /// 앞선 유효 세션도, 앞선 날의 점수도 없을 때만 "첫 측정"이다. 같은 날 두 번째 측정은 첫 측정이 아니다.
    private var isFirstMeasurement: Bool {
        let resultDay = Calendar.current.startOfDay(for: result.startedAt)
        let earlierValid = sessions.contains { $0.isValid && $0.startedAt < result.startedAt }
        let earlierDay = scores.contains { $0.day < resultDay }
        return !earlierValid && !earlierDay
    }

    /// 변주 번호 — 날짜에서 만든다. 같은 날엔 같은 문장, 날이 바뀌면 다른 문장(character-voice §8).
    private var rotation: Int {
        Calendar.current.ordinality(of: .day, in: .era, for: result.startedAt) ?? 0
    }

    /// 카탈로그 문장에 사실을 끼운다. 사실이 없는 대사(무효)는 숫자 자리가 없다.
    static func text(for line: VoiceLine) -> String {
        let template = String(localized: String.LocalizationValue(line.catalogKey))
        // 키가 카탈로그에 없으면 키 문자열이 그대로 나온다 — 개발 중에 바로 드러나게 한다.
        assert(template != line.catalogKey, "Missing String Catalog entry: \(line.catalogKey)")
        guard let facts = line.facts else { return template }
        return String(format: template, facts.score, facts.lapseCount)
    }
}
