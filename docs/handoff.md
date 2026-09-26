# 단계 인수인계 (Handoff)

> 단계(Phase)나 세션 경계에서 **맥락을 다음으로 넘기는** 문서.
> 대화가 길어져 요약·압축돼도 "어디까지 했고 다음에 뭘 하는지"가 살아남게 한다(헌법 제8조 3·4항).
> 새 세션은 진실의 원천 순서(`collaboration.md` §3)를 본 뒤, 이 파일의 **최신 인수인계**로 이어서 시작한다.

- **최종 수정:** 2026-09-26 (Phase 2 기록 보강 · 이슈 #4 마감 · 문서 정합)

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

## [2026-09-26] 정합 점검 — Phase 2 기록 보강 · 문서/GitHub 동기화

**한 줄 상태:** 전 파일·GitHub 상태를 실측 점검했다. 코드는 건강하다(테스트 70개 그린, 앱 빌드 성공, 로컬=원격). 다만 **Phase 2(PR #6)가 머지됐는데 문서가 한 단계 뒤처져** 있어 handoff·README·CONCEPT·data-model을 실제 상태로 맞추고, 이슈 #4를 Done-when 근거와 함께 닫고, 머지된 원격 브랜치를 정리했다. 새 기능 작업은 없음.

### ✅ 완료된 것 (검증됨)
- **실측:** `main` = `origin/main`(`ffe601b`), tree clean / `swift test` **70개·10 스위트 그린** / `xcodebuild` iPhone 17 Pro 시뮬 **BUILD SUCCEEDED** / String Catalog **31키 전부 ja·en·ko**
- **이 handoff에 Phase 2 항목 추가**(아래) — 지난 세션이 인수인계를 남기지 않았음
- **README Status** — "Phase 1·45 tests·점수는 이후"였던 것을 Phase 2 완료·70 tests·冴え度 점수 동작으로 교체
- **CONCEPT 다음 작업** — 점수화 완료, 추이 차트 남음으로 갱신 / **data-model** 헤더 날짜 정합
- **이슈 #4 CLOSED** — Done-when 5개를 PR #6 검증 기록과 대조해 체크 후 근거 코멘트와 함께 닫음
- **원격 브랜치 `phase2-sae-score` 삭제**(PR #6 머지 완료분)

### 🔄 진행 중 (미완)
- 없음

### ▶️ 다음 할 일 (우선순위 순)
1. **다음 페이즈 이슈 먼저 생성**(§7) — 2주차 잔여분인 **추이 차트(Swift Charts, `DailyScore` 일별)**. 이슈 올린 뒤 착수
2. 실기기 end-to-end → **#5**(기기 확보 시)
3. 보정 오프셋 실측(timing-engine §8-3) — 하드웨어 필요, 그전까지 미보정 유지
4. 3주차: CoreMotion 손떨림 · HealthKit HRV · 디자인 시스템

### 🧭 이번에 내린 결정 · 이유
- **문서 정합은 main에 직접 docs 커밋** — 코드 변경이 없고 과거 docs 정정(`41ed706`, `4b15023`)과 같은 관례
- **커밋 트레일러는 실제 작성 모델(Opus 5.5)** — 지난 결정(실제 모델을 적는다)을 그대로 따름

### ❓ 열린 질문 · 막힌 곳
- Phase 2 항목의 열린 질문 그대로(타당도 게이트 최소 응답 5, 하루 여러 측정 시 마지막 유효값 규칙, 타임아웃 10초의 문헌 근거)

### 🔬 검증 상태
- 순수 로직 70개 그린, 앱 빌드 성공. 이번 세션에 시뮬 런타임 재관찰은 하지 않음(PR #6 기록에 의존). 실기기·물리 보정 미검증 그대로

### 📎 관련 파일 · 커밋
- 문서: `docs/handoff.md`, `README.md`, `docs/CONCEPT.md`, `docs/data-model.md`
- 이슈: **#4 CLOSED**(2026-09-26) · #5 OPEN

## [2026-09-23] Phase 2 — 冴え度 점수(PVT 단독) · 결과 표시

> ※ 이 항목은 2026-09-26에 git·PR #6·이슈 #4를 실측해 **사후 작성**했다. 당시 세션이 인수인계를 남기지 않았다.

**한 줄 상태:** 끝난 PVT 세션이 **설명 가능한 冴え度(0~100)** 를 내고, `DailyScore`로 온디바이스 저장되며, 결과 화면에 그 점수를 만든 원지표가 3언어로 표시된다. 6커밋, **PR #6로 `main`에 머지**(`ffe601b`).

### ✅ 완료된 것 (검증됨)
- **스코프 확정** — MVP 점수는 **PVT 단독**(HRV·손떨림 앵커가 근거 부족), 세션 **12 trial · 타임아웃 10초** (`099d8e6`, `e87c087`)
- **하위지표 매핑** — lapse율·중앙 RT·가장 빠른 10% → 0~100 구간선형 보간 + 클램프 (`24a78f5`)
- **각성 성분** — 가중합 × false start 배수, 타당도 게이트 (`4f28de0`)
- **최종 점수** — 가용 성분 가중치 재정규화, 설명을 **문장이 아닌 데이터**로 (`7ac74c7`)
- **영속화·표시** — `DailyScore` 저장, 결과 화면 ja/en/ko (`6e7c92f`)
- **테스트:** `swift test` **70개 / 10 스위트 그린**(45→70). score-algorithm §6 워크드 예시(58.3 / 63.2 / 73.3 → 62.3 × 0.97 → 60.4 → **60**)를 그대로 재현
- **시뮬 관찰:** 유효 12-trial 세션 → **97점**(각성 96.8, lapse 0, 중앙 273ms), `DailyScore` 저장 / 무효 세션(false start 과다) → "점수 없음" 표시, `DailyScore` 불변 / 소요 77.5초

### 🧭 이번에 내린 결정 · 이유
- **점수는 PVT 단독** — 근거 약한 신호를 헤드라인 숫자에 섞으면 정직성을 가장 약한 근거에 건다(제2조). 재정규화 규칙은 일반형으로 구현
- **12 trial 고정(시간 고정 아님)** — lapse율 분모가 매번 달라지면 날짜 간 비교 불가
- **10초 타임아웃은 UX 판단** — 문헌 표준 미확인이라 "표준"이라 부르지 않음. 원자료로 재계산 가능
- **`explanation` 문자열 대신 원지표 저장** — 문장은 저장 시점 언어를 박제함(제5조). data-model에 반영
- **무효 세션은 점수를 만들지 않음** — 낮은 점수를 지어내지 않고 빈칸(제2조)

### ❓ 열린 질문 · 막힌 곳
- 타당도 게이트 **최소 응답 5**는 12 trial 대비 느슨 — 실데이터 전까지 유지
- 하루 여러 측정 시 **마지막 유효 측정**으로 갱신하는 규칙 — 실사용 후 재검토
- 여전히 **시뮬레이터 한정**(#5), `calibrationOffsetMs=0` 미보정

### 📎 관련 파일 · 커밋
- 순수 코어: `SaeTiming/Sources/SaeTiming/{SubIndex,ArousalScore,SaeScore}.swift` (+테스트)
- 앱: `Sae/{DailyScoreModel,PVTSessionStore,TimingLabView,SaeApp}.swift`, `Sae/Localizable.xcstrings`
- PR: **#6 MERGED** / 이슈: #4(Phase 2)

## [2026-09-22] Phase 1 — 시계 계약 · 세션 배선 · 영속화 (C·D·E)

**한 줄 상태:** 지난 세션이 남긴 C·D·E를 한 번에 끝냈다. 시계 계약을 순수 명세 + 런타임 실측으로 **양쪽 다 검증**했고, 온셋과 탭을 묶어 **PVT 세션이 end-to-end로 돌아가며**, trial 원자료가 **SwiftData에 남아 앱 재실행 후에도 살아남는** 것까지 확인했다. README·data-model 정합까지 6커밋. **PR #3(12커밋)로 `main`에 머지 완료**(`4871926`), 작업 브랜치는 삭제. ~~이슈 #1은 계속 OPEN — "on device" Done-when이 시뮬레이터로는 충족되지 않기 때문.~~

> **※ 2026-09-23 정정:** 위 문장은 틀렸다. #1의 해당 조항은 실제로 **"on device/simulator"** 이고, 시뮬레이터 실행으로 충족된다. 기준을 문서에서 읽지 않고 기억으로 옮기면서 더 엄하게 왜곡했다(제8조 1항 위반). **#1은 Scope 8개·Done-when 4개 전부 충족으로 2026-09-23에 CLOSED**했고, 실기기 검증은 기준을 사후에 올리는 대신 **별도 이슈 #5**로 분리했다. PR #3 본문에도 같은 문장이 있어 정정 코멘트를 달았다.

### ✅ 완료된 것 (검증됨)

- **C① 시계 계약 순수 명세** — `ClockContract.verify(sampleTs:referenceTs:tolerance:)`가 부호 있는 차이와 판정을 낸다. 경계·대칭·벽시계 혼입·다른 단조 기준까지 **9개 테스트**. 허용오차 0.25초는 "정밀도 판정"이 아니라 **기준 식별**용이라는 근거를 주석에 남김 (`36ef22a`)
- **C② 런타임 실측** — `CADisplayLink.timestamp`는 첫 프레임에서, `UITouch.timestamp`는 매 탭마다 `CACurrentMediaTime()`과 대조. DEBUG에서 위반 시 assert, 화면에 Δ와 판정 노출. **시뮬 실측: 프레임 Δ 0.0~15.8ms, 터치 Δ 4.1~16.7ms — 전부 동일 단조 기준** (`370a2fe`)
- **D 세션 배선** — 대기→자극→응답→다음 대기 사이클 완성. 시뮬 관찰: **유효 세션**(RT 367.7/332.9/309.4/263.7/381.2ms, 중앙값 332.9, 랩스 0, FS 0) / **무효(FS 과다)** / **무효(응답 부족)** / **무응답(30초 타임아웃)** 4경로 전부 확인 (`4efb93d`)
- **E 영속화** — 세션 1 + trial 5가 SwiftData에 저장되고 **앱 재실행 후에도 유지**. SQLite 직접 확인: ISI 5847/6887/2066/9509/7270ms(전부 2~10초), `displayRefreshHz=60`, `calibrationOffsetMs=0`, `isValid=1`, `durationMs=33295` (`4125ec5`)
- **문서 정합** — README Status가 "No app code yet"으로 거짓이던 것을 실제 상태로 교체(+ 미보정·시뮬한정을 명시). data-model에 `invalidReason`·`stimulusAt` optional 반영 (`a91d116`)
- **테스트:** `swift test` **45개 / 7 스위트 그린**. 앱 빌드 성공(Xcode 26.4, iPhone 17 Pro / iOS 26.4 시뮬)

### 🔄 진행 중 (미완)

- 없음. 6커밋 전부 `main`에 머지됨(PR #3)

### ▶️ 다음 할 일 (우선순위 순)

1. ~~이슈 #1 본문 체크박스 갱신~~ · ~~브랜치 정리~~ → **완료(2026-09-23 / 2026-09-22)**. #1은 CLOSED
2. **실기기 end-to-end** → **이슈 #5로 분리**(오늘은 기기 없음). 120Hz ProMotion 주사율·온셋 불확실성 확인 포함
3. **보정 오프셋 실측**(timing-engine §8-3) — 포토다이오드 하드웨어 필요. 확보 전까지 0/미보정 유지 (#5 Out of scope에 240fps 근사 대안 기록)
4. **Phase 2** → **이슈 #4 생성 완료**, 착수함. 冴え度 점수화(PVT 단독) + 결과 표시. Charts 추이는 그다음

### 🧭 이번에 내린 결정 · 이유

- **자극 온셋 = `targetTimestamp`(직전 프레임 `timestamp` 아님)** — 콜백에서 플래그를 켜면 그 변경은 *지금 준비 중인* 프레임에 실려 나간다. `timestamp`를 쓰면 온셋을 한 프레임(60Hz 16.7ms) 이르게 잡아 **모든 RT가 그만큼 부풀려진다**. 프레임 드랍 시 실제 점등이 더 늦어지는 잔여 오차는 상수로 못 없애므로 정직하게 남김(제1조 2항, §7)
- **스케줄 다음 목표 = trial 종료 시각 기준**(온셋 기준 아님) — 응답에 걸린 시간을 0으로 가정하면 느린 응답 때 다음 자극이 **겹쳐 뜬다**. 상태기계를 `waiting`/`showingStimulus`/`finished`로 명시화
- **false start도 순수 `TrialClassifier`로 판정** — 앱에서 `.falseStart`를 직접 만들면 분류 규칙이 코어와 갈라져, 테스트가 증명한 것과 실제가 달라진다. 또한 false start는 **trial을 소비하지 않는다**(자극은 여전히 온다)
- **스키마 2건 변경 + 문서 반영** — `PVTSession.invalidReason`(왜 무효인지, 제2조 2항), `PVTTrial.stimulusAt` optional(false start엔 자극이 없었다 — 예정 시각을 표시된 것처럼 적으면 날조). 조용히 어긋나게 두지 않고 data-model.md를 고침
- **커밋 트레일러를 `Claude Opus 5`로** — `collaboration.md` §7 예시는 4.8이지만 실제 작성 모델을 적는 게 정직(제2조). 문서의 예시 문자열은 손대지 않음
- **시뮬 탭 자동화 방법을 찾음** — `simctl`엔 탭이 없지만 **CGEvent(마우스 다운/업) 포스팅이 통한다**(접근성 권한이 이제 허용됨). 자극 점등 판정은 `simctl io screenshot --type=bmp` + BMP 픽셀 직접 읽기. 지난 세션의 "수동 탭만 가능" 제약이 풀림

### ❓ 열린 질문 · 막힌 곳

- **실기기 미검증** — 전부 시뮬레이터 관찰이다. 터치 스캔 지연·패널 응답은 실기기에서 달라진다
- **보정 오프셋 미측정** — 하드웨어 필요, `calibrationOffsetMs=0`("미보정") 유지
- **세션 trial 수 5는 임시** — 90초 세션의 최종 trial 수는 score-algorithm 열린 결정. 원자료를 남기므로 나중에 조정 가능
- **타임아웃 30초가 UX상 긴가** — PVT 표준값을 따랐지만, 실사용에선 무응답 1건에 30초를 버린다. Phase 2에서 재검토

### 🔬 검증 상태

- **순수 로직:** `swift test` 45개 그린(RT수학·분류·ISI·집계·타당도·자극스케줄·시계계약)
- **런타임 관찰(유닛 아님):** 시계 계약 양쪽 실측 / 세션 4경로 / 저장·재실행 유지 / SQLite 원자료 직접 확인
- **미검증:** 실기기 end-to-end, 물리 보정 오프셋(§8-3), 120Hz 환경

### 📎 관련 파일 · 커밋

- 순수 코어: `SaeTiming/Sources/SaeTiming/{ClockContract,StimulusSchedule}.swift` (+테스트)
- 앱 런타임: `Sae/{PVTSessionRunner,RuntimeClockCheck,TouchCatcher,TimingLabView}.swift`
- 영속화: `Sae/{PVTSessionModels,PVTSessionStore,SaeApp}.swift`
- 커밋: `36ef22a`(C①) · `370a2fe`(C②) · `4efb93d`(D) · `4125ec5`(E) · `a91d116`(문서) · `5605e24`(인수인계)
- PR: **#3 MERGED** (12커밋, 머지 커밋 `4871926`) / 브랜치: `phase1-timing-runtime` 머지 후 삭제 / 이슈: **#1 CLOSED**(2026-09-23, 위 정정 참고) · 후속 **#5**(실기기) · **#4**(Phase 2)
- 참고: `docs/timing-engine.md` §2·§3·§7·§8-2, `docs/data-model.md`

## [2026-07-26] Phase 1 — 앱 셸 + 타이밍 런타임 A/A'/B (이슈 상태 정정)

**한 줄 상태:** 지난 세션에 만든 앱 셸(미기록)을 실측 반영하고, 타이밍 런타임을 사이클 단위로 A(순수 자극 스케줄러)·A'(CADisplayLink 배선)·B(저수준 UITouch)까지 구현·커밋했다. **이슈 #1이 COMPLETED로 잘못 닫혀 있던 것을 재오픈**하고(제2조), 재발 방지 규칙을 메모리에 남겼다. C(시계 계약)부터는 다음 세션.

### ✅ 완료된 것 (검증됨)
- **GitHub 상태 정정(실측):** PR #2 = **MERGED**(순수 코어가 origin/main `de7c239`에 병합), 이슈 #1 = 지난 세션에 **COMPLETED로 오마감** → **재오픈**(OPEN/REOPENED). Done-when(런타임·시계계약·SwiftData·end-to-end) 미완이라 정직성 위반이었음. 코멘트로 남은 범위 명시
- **재발 방지 메모리:** `collaboration-protocol.md`에 "이슈는 Done-when 전부 충족 시에만 닫기" + "상태 기록 전 gh/git 실측" 2규칙 추가
- **브랜치 정리:** 로컬 `main`을 `origin/main`으로 ff. 새 작업 브랜치 `phase1-timing-runtime` 생성(머지된 옛 `phase1-timing-engine` 재사용 회피)
- **앱 셸(지난 세션, 이번에 실측 반영):** SwiftUI 셸 + ja/en/ko String Catalog + SaeTiming 링크. 시뮬 3언어 렌더 확인 (`7cc7fd1`, `102b19d`)
- **A — 순수 자극 스케줄러:** `StimulusSchedule`(ISI 소비 + `frameTime ≥ target` 첫 프레임 온셋 확정, 다음 목표=실제 온셋+ISI). Swift Testing 7개 추가 → **33개 그린** (`b0fa29d`)
- **A' — CADisplayLink 드라이버:** `StimulusRunner`가 순수 스케줄에 실제 프레임 타임스탬프 공급. 시뮬 실측: **60Hz**, 온셋 5개, 간격 6.90/2.07/9.52/7.28s(전부 2–10s ISI). dev용 `TimingLabView` + `-autolab` 실행인자 딥링크(#if DEBUG) (`9ee2817`)
- **B — 저수준 UITouch:** `TouchCatcher`(UIViewRepresentable, `touchesBegan`의 `touch.timestamp`, 고수준 제스처 금지). 시뮬 탭 실측 23529.616s가 온셋(~23427s)과 **동일 단조 스케일** → 시계 계약 전제 실기 확인 (`55b184f`)

### 🔄 진행 중 (미완)
- 없음. 각 사이클은 빌드/테스트/관찰 후 커밋 완료. `phase1-timing-runtime` origin에 push됨(PR 미생성)

### ▶️ 다음 할 일 (우선순위 순) — 이슈 #1의 남은 범위
1. **C — 시계 계약 테스트** (다음 세션 착수 지점): 순수 유닛으로 완전증명 불가(런타임 사실). 계획 = ① `SaeTiming`에 "샘플이 공통기준 `CACurrentMediaTime`과 허용오차 내면 같은 단조 기준" 순수 명세 + 경계 테스트, ② 앱에서 `CADisplayLink.timestamp`·`UITouch.timestamp`를 각각 `CACurrentMediaTime()`과 실측 비교 + 디버그 assert (timing-engine §8-2)
2. **D — 1 trial → 세션 배선:** A'(온셋)+B(탭) 묶어 RT 계산 → `SaeTiming` 분류/집계 연결. 자극 시각화(플래그 토글, 애니메이션 금지) 포함
3. **E — SwiftData 영속화:** `PVTTrial` 원자료 + `PVTSession.displayRefreshHz`/`calibrationOffsetMs`
4. 런타임 완성 후 새 PR로 `origin/main`에 올리고 #1 Done-when 충족분 반영

### 🧭 이번에 내린 결정 · 이유
- **이슈 #1 재오픈** — Done-when 미완인데 COMPLETED는 미완을 완료로 오표기(제2조). core 완료는 PR #2가 이미 증명하므로 재오픈해도 성과는 남고 원래 정의와 일치
- **순수/런타임 물리 분리 유지** — 온셋 판정(A)·시계 계약 명세(C①)는 `SaeTiming`에서 `swift test`로 증명, CADisplayLink·UITouch 배선(A'·B·C②)은 앱에서 시뮬 관찰. 정확도는 순수층이 증명하고 런타임층은 "실제 타임스탬프 전달"만 책임(제1조 3항)
- **`-autolab` 딥링크 훅(#if DEBUG)** — simctl에 탭 기능 없고 osascript는 접근성 권한(-1719)에 막힘 → 실행인자로 랩 자동 진입. 릴리즈엔 빠짐
- **pbxproj 재포맷 노이즈는 커밋서 제외** — xcodebuild가 동기화 그룹 정의를 재포맷하나 기능 동일, 소스 커밋 오염 방지 위해 `git checkout`으로 원복

### ❓ 열린 질문 · 막힌 곳
- **시뮬 탭 자동화 불가** — simctl 탭 없음·osascript 접근성 차단·idb 미설치. 터치 관련 검증은 사용자 수동 탭 + 스크린샷으로 관찰(이번 B가 그 방식). 자동화 원하면 접근성 권한 부여 또는 idb 설치 필요
- **보정 오프셋 미측정** — 포토다이오드 하드웨어 필요, `calibrationOffsetMs`=0 "미보정" 유지(§8-3)
- C의 순수 명세 tolerance 값은 구현 중 실측(프레임 이내)으로 확정

### 🔬 검증 상태
- **Swift Testing 33개 그린**(순수 로직: RT수학·분류·ISI·집계·타당도·자극스케줄). Build 성공(Xcode 26.4)
- **런타임 관찰(유닛 아님):** A' 온셋 캡처·주사율, B 탭 캡처·시계 스케일 일치 — 시뮬 스크린샷으로 확인
- **미검증:** 시계 계약 자동 assert(C), 보정 오프셋 물리 실측(§8-3), on-device end-to-end(D·E)

### 📎 관련 파일 · 커밋
- 순수 코어: `SaeTiming/Sources/SaeTiming/StimulusSchedule.swift` (+테스트)
- 앱 런타임: `Sae/{StimulusRunner,TouchCatcher,TimingLabView,ContentView}.swift`, `Sae/Localizable.xcstrings`
- 브랜치: `phase1-timing-runtime` (origin push, PR 미생성) / 커밋: `7cc7fd1`·`102b19d`·`b0fa29d`·`9ee2817`·`55b184f` / 이슈: #1 (재OPEN)
- 참고: `docs/timing-engine.md` §3·§4·§8-2

## [2026-07-21] Phase 1 — PVT 타이밍 코어 (순수 모듈, 첫 구현)

**한 줄 상태:** Mac+Xcode 환경에서 Phase 1 착수. PVT 반응시간의 **순수 코어**(`SaeTiming` Swift 패키지)를 구현하고 Swift Testing 26개로 로직 정확도를 증명, 레포 루트에 6커밋으로 나눠 드래프트 PR #2로 올렸다. **UIKit 런타임·SwiftData·앱 셸은 아직 없음 — 이슈 #1은 계속 OPEN.**

### ✅ 완료된 것 (검증됨)
- `SaeTiming` 로컬 Swift 패키지 (레포 루트, `.claude` 밖) — 순수·플랫폼 독립, `swift test`로 시뮬레이터 없이 검증
- `ReactionTime.milliseconds` — RT=(touch−stim)×1000−offset, 부호·분수ms 보존 (timing-engine §4)
- `TrialClassifier` — valid / lapse(>500ms) / falseStart(자극 전 탭, 음수 방지) / noResponse(타임아웃) 분류
- `ISIScheduler` + `SeededGenerator` — 시드 고정 결정적 ISI 2~10초 (SplitMix64, 재현 가능)
- `PVTSessionSummary` — mean/median RT · fastest10% · lapse/falseStart/noResponse 카운트 (data-model `PVTSession` 요약 필드)
- `SessionValidator` — falseStart≥3 또는 유효 trial<5 → 무효, 사유 보존 (score-algorithm §1-3)
- **Swift Testing 26개 그린** (5 suites): 합성 타임스탬프 주입 · 경계값(lapse 500 배타, 음수 방지, 타임아웃, 오프셋 lapse경계) · 집계(홀짝 중앙값·빈 세션·무응답 제외) · 타당도 게이트 경계
- 환경 발견: **Xcode 26.4가 실제로 설치돼 있음.** `xcode-select`가 CLT를 가리켜 `xcodebuild`가 실패했던 것 → `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`로 sudo 없이 사용(iOS 26.4 시뮬레이터 존재). `swift test`도 이 툴체인으로

### 🔄 진행 중 (미완)
- 없음 (순수 코어는 마무리). 아래 런타임 항목은 착수 전 — **이슈 #1의 남은 Done-when**이다.

### ▶️ 다음 할 일 (우선순위 순) — 전부 이슈 #1의 남은 범위
1. **iOS 앱 Xcode 셸** — SwiftUI 앱, min iOS 17, String Catalog(`.xcstrings`) 처음부터(제5조), 로컬 `SaeTiming` 의존
2. **타이밍 런타임 배선** — 자극 온셋=`CADisplayLink` 프레임 타임스탬프, 응답=`UITouch.timestamp` 저수준 경로(고수준 제스처 금지), ISI를 CADisplayLink로 소비 (timing-engine §3·§4·§6)
3. **시계 계약 테스트** — `UITouch.timestamp`와 `CADisplayLink.timestamp`가 같은 단조 기준인지 (timing-engine §8-2, #1 Done-when)
4. **SwiftData 영속화** — `PVTTrial` 원자료 + `PVTSession.displayRefreshHz`/`calibrationOffsetMs` (data-model)
5. **온디바이스 1회 세션 end-to-end** — trial 원자료 저장까지 (#1 Done-when)

### 🧭 이번에 내린 결정 · 이유
- **"iOS 앱 + 내부 모듈" = 앱 프로젝트 + 로컬 SPM 패키지** — 정확도 엔진을 `swift test`로 시뮬레이터 없이 증명하고 측정/표현 계층을 물리적으로 분리(timing-engine §6). 순수 코어 먼저, 앱 셸은 다음 사이클
- **테스트는 Swift Testing** (XCTest 아님) — tech-stack 우선순위
- **기본 상수:** 타임아웃 30초 · lapse 500ms · 유효 trial 최소 5 · falseStart 무효 임계 3 — 문서 기본값 채택, 원자료 보존이라 재조정 가능(열린 결정)
- **작업 위치를 `.claude/worktrees`→ 레포 루트로 이동** — 사용자 요청. bgIsolation 해제 플래그는 `settings.local.json`(gitignore, 미커밋)
- **이슈 #1은 닫지 않고 OPEN 유지** — Done-when 다수(온디바이스 런타임·SwiftData·시계계약·end-to-end)가 미완. 순수 코어만 완료로 닫으면 미완을 완료로 오표기(제2조). 남은 범위를 #1에 그대로 둔다

### ❓ 열린 질문 · 막힌 곳
- PR #2 머지 시점(드래프트) — 리뷰 후. 머지해도 #1은 런타임까지 열어둠
- 보정 상수 실측(포토다이오드)은 하드웨어 필요 → offset "미보정"(0) 유지 (timing-engine §8-3)
- 시계 계약(§8-2)·on-device 런타임은 실기기/시뮬레이터 필요 — 다음 사이클

### 🔬 검증 상태
- **Swift Testing 26개 통과** (로직 정확도, timing-engine §8-1). Build 성공(Xcode 26.4 툴체인)
- **미검증:** 절대 오프셋 물리 보정(§8-3, 하드웨어) · 시계 계약(§8-2, 실기기) · on-device 런타임 — 전부 다음 사이클/하드웨어

### 📎 관련 파일 · 커밋
- 코드: `SaeTiming/Sources/SaeTiming/{ReactionTime,TrialOutcome,ISIScheduler,PVTSessionSummary,SessionValidator}.swift`
- 테스트: `SaeTiming/Tests/SaeTimingTests/*`
- 브랜치: `phase1-timing-engine` (head `b163945`), 6커밋 / PR: #2 (draft) / 이슈: #1 (OPEN)

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
