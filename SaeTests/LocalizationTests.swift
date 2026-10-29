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
}
