import Foundation
import Testing
@testable import Sae

/// 3언어 동등성(헌법 제5조) — 빌드된 앱 안의 문자열 표를 직접 읽어 검사한다.
///
/// String Catalog(`.xcstrings`)는 빌드 때 언어별 `.lproj/*.strings`로 컴파일된다. 원본 카탈로그가 아니라
/// **사용자 기기에 실제로 실리는 결과물**을 본다.
struct LocalizationTests {
    static let languages = ["en", "ja", "ko"]
    static let tables = ["Localizable", "InfoPlist"]

    /// 앱 번들에서 한 언어의 한 표를 읽는다. (호스트 앱에서 도는 테스트라 `Bundle.main`이 앱이다.)
    static func strings(_ table: String, _ language: String) -> [String: String] {
        guard let path = Bundle.main.path(forResource: table, ofType: "strings", inDirectory: nil,
                                          forLocalization: language),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String]
        else { return [:] }
        return dict
    }

    @Test(arguments: tables)
    func everyKeyExistsInAllThreeLanguages(table: String) {
        let byLanguage = Dictionary(uniqueKeysWithValues: Self.languages.map { ($0, Self.strings(table, $0)) })
        let english = Set(byLanguage["en", default: [:]].keys)
        #expect(!english.isEmpty, "\(table): 영어 표가 비어 있지 않다")
        for language in Self.languages {
            let keys = Set(byLanguage[language, default: [:]].keys)
            #expect(keys == english,
                    "\(table)/\(language): 빠진 키 \(english.subtracting(keys).sorted()), 남는 키 \(keys.subtracting(english).sorted())")
        }
    }

    @Test(arguments: tables)
    func noTranslationIsEmpty(table: String) {
        for language in Self.languages {
            let empty = Self.strings(table, language).filter { $0.value.trimmingCharacters(in: .whitespaces).isEmpty }
            #expect(empty.isEmpty, "\(table)/\(language): 빈 번역 \(empty.keys.sorted())")
        }
    }

    /// 형식 지정자 하나 — 몇 번째 인자에, 어떤 종류·정밀도로 들어가는가.
    struct Specifier: Equatable, Comparable, CustomStringConvertible {
        let position: Int
        let kind: String
        static func < (a: Self, b: Self) -> Bool { a.position < b.position }
        var description: String { "%\(position)$\(kind)" }
    }

    /// 문자열의 형식 지정자들. `%1$lld`처럼 위치가 있으면 그 위치로, 없으면 나타난 순서대로 번호를 매긴다.
    /// `%%`(퍼센트 기호)는 지정자가 아니다.
    static func specifiers(in text: String) -> [Specifier] {
        let pattern = #"%(?:(\d+)\$)?([-+ #0]*\d*(?:\.\d+)?(?:lld|ld|d|i|u|@|f|e|g))"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let cleaned = text.replacingOccurrences(of: "%%", with: "")
        let range = NSRange(cleaned.startIndex..., in: cleaned)
        return regex.matches(in: cleaned, range: range).enumerated().map { index, match in
            let position = Range(match.range(at: 1), in: cleaned).flatMap { Int(cleaned[$0]) } ?? index + 1
            let kind = Range(match.range(at: 2), in: cleaned).map { String(cleaned[$0]) } ?? ""
            return Specifier(position: position, kind: kind)
        }.sorted()
    }

    /// 같은 문구의 세 언어가 같은 인자를 같은 형식으로 받는다 — 빠지거나 종류가 바뀌면 실행 중에
    /// 엉뚱한 숫자가 나오거나 앱이 멈출 수 있다.
    @Test(arguments: tables)
    func translationsKeepTheSameFormatSpecifiers(table: String) {
        let english = Self.strings(table, "en")
        for language in ["ja", "ko"] {
            let translated = Self.strings(table, language)
            for (key, source) in english {
                guard let target = translated[key] else { continue } // 빠진 키는 위 테스트가 잡는다
                let expected = Self.specifiers(in: source)
                let actual = Self.specifiers(in: target)
                #expect(actual == expected, "\(table)/\(language) '\(key)': \(actual) ≠ en \(expected)")
            }
        }
    }

    /// 검사기 자체의 동작 — 위치 지정은 순서를 바꿔도 같고, 종류·정밀도가 다르면 다르다.
    @Test func specifierParsing() {
        #expect(Self.specifiers(in: "%1$lld of %2$lld") == Self.specifiers(in: "%2$lld日のうち%1$lld日"))
        #expect(Self.specifiers(in: "%.0f ms") != Self.specifiers(in: "%.1f ms"))
        #expect(Self.specifiers(in: "%lld / %lld").map(\.position) == [1, 2])
        #expect(Self.specifiers(in: "100%% sure").isEmpty)
    }
}
