# 단계 인수인계 (Handoff)

> 단계(Phase)나 세션 경계에서 **맥락을 다음으로 넘기는** 문서.
> 대화가 길어져 요약·압축돼도 "어디까지 했고 다음에 뭘 하는지"가 살아남게 한다(헌법 제8조 3·4항).
> 새 세션은 진실의 원천 순서(`collaboration.md` §3)를 본 뒤, 이 파일의 **최신 인수인계**로 이어서 시작한다.

- **최종 수정:** 2026-07-20 (Phase 1 착수 직전)

---

## 쓰는 법

1. 단계를 마치거나 긴 세션을 접을 때, 아래 **템플릿을 복사**해 이 문서 맨 위(최신이 위)에 붙인다.
2. 빈칸을 채운다. 모르면 "모름"이라 쓴다 — 꾸미지 않는다(제9조 5항).
3. 검증되지 않은 건 "미검증"으로 명시한다. 됐고 검증됐으면 담백하게 "완료".
4. 이어서 일할 때는 최신 인수인계의 **"다음 할 일"부터** 시작한다. 조기 마무리하듯 굴지 않는다(제8조 4항).

**단계 정의:** MVP 4주 계획(`CONCEPT.md` §7) — 1주차 PVT 엔진 / 2주차 점수화·차트 / 3주차 CoreMotion·HealthKit·디자인 / 4주차 온보딩·마감·다국어.

---

## 템플릿 (복사해서 사용)

```markdown
## [YYYY-MM-DD] Phase N — <단계 이름>

**한 줄 상태:** <이번 세션에서 전체적으로 무슨 일이 있었나>

### ✅ 완료된 것 (검증됨)
- <무엇 — 어떻게 검증했는지 한 줄>

### 🔄 진행 중 (미완)
- <무엇 — 어디까지 됐고 뭐가 남았나>

### ▶️ 다음 할 일 (우선순위 순)
1. <가장 먼저 할 것>
2. <그다음>

### 🧭 이번에 내린 결정 · 이유
- <무엇을 정했나> — <왜> (관련 조항/커밋: ___)

### ❓ 열린 질문 · 막힌 곳
- <사용자 확인이 필요한 것 / 불확실한 것>

### 🔬 검증 상태
- <테스트 통과/실패, 미검증 항목. 특히 정확도 엔진(제1조)은 명시>

### 📎 관련 파일 · 커밋
- 코드: `경로/파일.swift`
- 커밋: `<sha 또는 요약>`
- 참고 문서: ___
```

---

## 인수인계 로그 (최신이 위)

<!-- 여기부터 실제 인수인계를 쌓는다. 최신 항목을 이 줄 바로 아래에 붙인다. -->

## [2026-07-20] Phase 1 착수 준비 — 이슈 생성 (Mac 환경 전환)

**한 줄 상태:** 다른(Windows) 컴퓨터가 force-push한 Phase 0.5 설계 문서군을 Mac에서 pull·정렬하고, **Phase 1 GitHub 이슈 #1을 영어로 생성**했다. 코드는 아직 없음 — 다음 세션에서 착수.

### ✅ 완료된 것 (검증됨)
- 원격 force-update 동기화: 로컬 고유 변경 없음 확인 후 `git reset --hard origin/main` (`feae8a2`). 로컬=원격 일치, tree clean
- 새 설계 3문서 정독·파악: `timing-engine.md`·`score-algorithm.md`·`character-voice.md` + 영어 `README`
- **Phase 1 이슈 #1 생성**: `Phase 1: PVT reaction-time engine` (영어, §7 틀 — Goal/Scope/Done when/Out of scope/Constitution). https://github.com/2daKaizen-gun/sae/issues/1
- `gh` 활성계정 `2daKaizen-gun`(keyring, repo scope) 확인 — 이 레포 소유자와 일치
- SessionStart 훅 저장·커밋 확인, 이번 세션에서 실제 발동 확인

### 🔄 진행 중 (미완)
- 없음 (이슈까지만. Phase 1 구현은 다음 세션)

### ▶️ 다음 할 일 (우선순위 순)
1. **Phase 1 구현 착수** (이슈 #1) — PCTC: Plan→Code부터. **여기부터 Xcode 필요, 현재 세션은 Mac(darwin)이라 가능**
2. **Xcode 프로젝트 셋업**: SwiftUI 앱, min iOS 17, String Catalog(`.xcstrings`) 처음부터(제5조)
3. **순수 타이밍 함수 + 합성 타임스탬프 테스트부터**(제1조 3항) — `rt(stimulusTs, touchTs, offset)`, lapse/false-start 분류, 시드 ISI 스케줄러. 설계는 `timing-engine.md` §8

### 🧭 이번에 내린 결정 · 이유
- **환경 전환: Windows → Mac** — handoff의 "빌드 불가" 제약이 풀림. Phase 1 실제 구현·정확도 테스트 가능
- **이슈 먼저, 코드는 다음 세션** — §7(페이즈 시작 전 이슈)·§9(한 번에 하나씩) 준수. 사용자가 여기서 세션 종료 선택

### ❓ 열린 질문 · 막힌 곳
- 보정 상수 실측(포토다이오드)은 여전히 별도 하드웨어 필요 → 그전까지 offset "미보정" 표기(timing-engine §8-3)
- 타임아웃 문턱·최소 유효 trial 수 등은 구현 중 확정(timing-engine·score-algorithm 열린 결정)

### 🔬 검증 상태
- **코드·테스트 없음.** 이슈·문서·동기화 상태만. 정확도 엔진 증명은 Phase 1 구현부터

### 📎 관련 파일 · 커밋
- 이슈: #1 (https://github.com/2daKaizen-gun/sae/issues/1)
- 설계: `docs/timing-engine.md`, `docs/score-algorithm.md`, `docs/data-model.md`
- 현재 HEAD: `feae8a2`

## [2026-07-20] Phase 0.5 — 계획 문서 보강 (설계 문서군)

**한 줄 상태:** 레포를 Windows 환경에 클론하고, 코드 전에 **핵심 설계 문서 3개 + README**를 채웠다. 초기 한글 커밋을 영어로 재작성하고 전 커밋을 영어로 통일(§7)했다. 코드는 여전히 없음(Windows라 Xcode 빌드 불가).

### ✅ 완료된 것 (검증됨)
- `docs/score-algorithm.md` — 冴え度 0~100 화이트박스 설계(성분·가중치·결측 재정규화·워크드 예시·한계). 커밋 `009b501`
- `docs/timing-engine.md` — 밀리초 타이밍·보정·테스트 전략(CADisplayLink 온셋·UITouch.timestamp·단조시계·미검증 항목 명시). 커밋 `3cee740`
- `docs/character-voice.md` — さえちゃん 페르소나·3단 대사구조·점수대 톤맵·3언어 데모·안전목록. 커밋 `6a3bc4c`
- `README.md` — 영어 포트폴리오 얼굴(왜·측정·엔지니어링 하이라이트·문서지도·정직한 status). 이 커밋
- **커밋 히스토리 전면 영어화**: 한글 커밋 `d233b37` → `39277dc`(영어, 본문까지 번역, filter-branch) + force-push 완료. 로컬=원격 일치
- **인증 해결**: 푸시가 `yigun03`(권한없음)로 막혀 gh 활성계정을 소유자 `2daKaizen-gun`으로 전환해 성공. 전역 git 설정 미변경
- 각 신규 문서를 CLAUDE.md·collaboration §8 문서지도에 연결, CONCEPT 다음작업 체크리스트 갱신

### 🔄 진행 중 (미완)
- 없음 (문서 보강 마무리)

### ▶️ 다음 할 일 (우선순위 순)
1. **Phase 1 시작 전 GitHub 이슈 먼저 생성** — 영어, `Phase 1: PVT reaction-time engine` (collaboration §7)
2. **Phase 1 — PVT 반응시간 엔진 구현** — 단, **Mac + Xcode 필요**(Windows에선 빌드·정확도 테스트 불가). 설계는 `timing-engine.md`·`score-algorithm.md`에 준비됨. 순수 타이밍 함수 + 합성 타임스탬프 테스트부터(제1조 3항)

### 🧭 이번에 내린 결정 · 이유
- **코드 전에 설계 문서를 두껍게** — Windows 환경 제약 + 제1·2조(정확도·설명가능성은 종이에서 먼저 확정). 세 문서 모두 "튜닝 대상/미검증"을 정직히 분리
- **전 커밋 영어 통일** — 포트폴리오 공개기록(§6·§7). 히스토리 재작성 + force-push는 1인 레포라 저위험으로 판단, 사용자 승인 후 진행

### ❓ 열린 질문 · 막힌 곳
- **Phase 1 코드를 어느 환경에서** 짤지 — Mac+Xcode 필요. 현재 Windows
- **gh 활성 계정이 `2daKaizen-gun`으로 바뀐 상태** — 이 레포엔 맞음. 되돌리려면 `gh auth switch --user yigun03`
- 보정 상수(timing-engine §5·8-3)는 실기기+포토다이오드 확보 후 실측 — 그 전엔 "미검증"

### 🔬 검증 상태
- **문서만. 코드·앱 테스트 없음.** 각 문서가 참조한 스키마 필드(`data-model.md`)·이름/태그라인(`CONCEPT.md`) 정합성은 확인함. 정확도 엔진 실측은 Phase 1(Mac)에서

### 📎 관련 파일 · 커밋
- 문서: `docs/score-algorithm.md`, `docs/timing-engine.md`, `docs/character-voice.md`, `README.md`
- 커밋: `009b501`, `3cee740`, `6a3bc4c`, `39277dc`(재작성), README 커밋
- 레포: https://github.com/2daKaizen-gun/sae

## [2026-07-19] Phase 0 — 셋업

**한 줄 상태:** 기획·헌법 확정, GitHub 레포 연결, 협업 문서군 + 데이터모델/기술스택 작성, 세션 시작 리추얼 훅 설정까지 완료. 코드는 아직 없음.

### ✅ 완료된 것 (검증됨)
- 기획서·헌법 초기 문서(`CONCEPT.md`, `CONSTITUTION.md`, `CLAUDE.md`) — 커밋·푸시 확인
- GitHub 레포 `2daKaizen-gun/sae` (public) 생성·연결, MIT License 유지, git author `2daKaizen-gun`로 설정
- 협업 문서군: `collaboration.md`, `workflow.md`(PCTC), `handoff.md`
- GitHub 규약: **커밋·이슈는 영어**, 페이즈 시작 전 이슈 먼저 생성 (collaboration §7)
- 시작 리추얼: `.claude/settings.json`의 `SessionStart` 훅 (JSON·실행 검증 완료)
- 데이터 모델 `data-model.md`(SwiftData ERD), 기술 스택 `tech-stack.md`

### 🔄 진행 중 (미완)
- 없음 (Phase 0 마무리, 커밋·푸시 완료)

### ▶️ 다음 할 일 (우선순위 순)
1. `README.md` 제대로 작성 — 영어, 포트폴리오 얼굴 (현재 `# sae` 플레이스홀더, 제6조)
2. **Phase 1 시작**: 시작 전 **GitHub 이슈 먼저 생성**(영어, `Phase 1: PVT reaction-time engine`) — 규약 §7
3. **Phase 1 — PVT 반응시간 엔진** (밀리초 정밀 타이밍, 정확도 테스트부터). Xcode 프로젝트 셋업(SwiftUI + String Catalog) 포함

### 🧭 이번에 내린 결정 · 이유
- PCTC = **Plan → Code → Test → Commit** 확정 — 표준 루프, 제1·6조와 정합
- 협업 규칙을 헌법에서 실천 문서로 분리 — 맥락 압축에도 살아남게(제8조)
- **커밋·이슈 영어 / 내부 문서·대화 한글** — 일본 취업 포트폴리오, 계층 분리(제5·6조)
- 반응시간을 **trial 단위 원자료로 저장** — 사후 검증·설명 가능성(제1·2조)

### ❓ 열린 질문 · 막힌 곳
- 노출됐던 `yigun03` 토큰 revoke 여부는 사용자 몫
- 최소 iOS 버전 17 유지 vs 상향 / `DailyScore` 집계 방식 — Phase 2 스키마 때 확정
- `SessionStart` 훅은 **다음 세션부터** 적용 (이번 세션엔 감시자가 못 잡음). 필요 시 `/hooks` 열거나 재시작

### 🔬 검증 상태
- 문서 단계 — 코드 없음, 테스트 없음. 훅은 JSON 유효성·실행 검증됨. 정확도 엔진은 Phase 1부터 테스트로 증명 예정

### 📎 관련 파일 · 커밋
- 문서: `docs/` (CONCEPT, CONSTITUTION, collaboration, workflow, handoff, data-model, tech-stack)
- 설정: `.claude/settings.json`
- 레포: https://github.com/2daKaizen-gun/sae
