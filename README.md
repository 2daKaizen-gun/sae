# 冴え (Sae)

> **Know your sharpness.** Measure your brain's alertness and sleep debt in 90 seconds a day — no wearable required.

冴え (*Sae*, from 「頭が冴える」— "the mind is sharp and clear") is a native iOS app that turns a
scientifically validated reaction-time test into a daily readout of how awake your brain really is.
No ring, no wrist band — just your phone and a 90-second micro-test.

Built as a portfolio piece for Japanese product ("自社開発") companies, with internationalization (JA / EN / KO) as a first-class design constraint.

| | Name | Character | Tagline |
|--|------|-----------|---------|
| 🇯🇵 | 冴え / さえ | さえちゃん | 「冴え」の言葉遊びがそのまま成立 |
| 🇬🇧 | Sae | Saechaan | *Know your sharpness* |
| 🇰🇷 | 사에 | 사에짱 | *당신의 각성을 재다* |

---

## Why

- **Japan is #1 in the OECD for sleep deprivation**, and "睡眠負債" (sleep debt) is a national buzzword — yet people can't reliably judge their own alertness.
- The **Psychomotor Vigilance Task (PVT)** is the sleep-science gold standard used by NASA and sleep labs: reaction time degrades in a precise, measurable way as sleep debt accumulates.
- Most reaction-time apps are *games* with no scientific grounding, and most sleep apps only track *while you sleep*. Sae actively measures **waking brain alertness** — the gap those apps leave open.

## What it measures

| Signal | Method | iOS tech | Meaning |
|--------|--------|----------|---------|
| **Alertness** | PVT reaction-time test (~60–90s) | High-precision timing (`CADisplayLink`) | Core sleep-debt indicator |
| **Autonomic / stress** | HRV (RMSSD) | HealthKit (Apple Watch) or camera PPG* | Recovery state |
| **Physical fatigue** | Physiological hand tremor | CoreMotion (~10s) | Accumulated fatigue |

These fuse into a daily **冴え度 (Sae-do) score, 0–100**, plus a trend chart. *(\*Camera PPG is a stretch goal.)*

## Engineering highlights

This project is deliberately built around a few hard problems, each designed before a line of code:

- **⏱ Millisecond-accurate reaction timing.** Measuring true reaction time on iOS is harder than it looks — most apps get it wrong. Stimulus onset is taken from the `CADisplayLink` frame timestamp and the response from `UITouch.timestamp` (hardware event time), so display and dispatch latency never contaminate the measurement. Calibration offset and refresh rate are stored per session for reproducibility. → [`docs/timing-engine.md`](docs/timing-engine.md)
- **🔍 An explainable score, not a black box.** Every point of the 0–100 Sae-do score maps back to raw PVT metrics — "why 60?" always has an answer. → [`docs/score-algorithm.md`](docs/score-algorithm.md)
- **🔒 Privacy by default.** All health data is processed on-device. No servers, no tracking, no ad SDKs.
- **🌏 Internationalization as a design premise.** Trilingual (JA / EN / KO) from day one via String Catalog (`.xcstrings`) — no hardcoded strings, all three languages treated as equal. → [`docs/character-voice.md`](docs/character-voice.md)
- **🌡 Cold data, warm delivery.** A character layer (*Saechaan*) delivers hard numbers gently — warming the tone without ever distorting the data.

## Tech stack

Native Apple stack, zero third-party dependencies by default: **SwiftUI · SwiftData · Swift Charts · CADisplayLink / `mach_absolute_time` (precision timing) · CoreMotion · HealthKit · String Catalog · Swift Testing.** Minimum iOS 17.
→ [`docs/tech-stack.md`](docs/tech-stack.md)

## Design principles

Development is governed by a small **[project constitution](docs/CONSTITUTION.md)** — a top-level set of rules that any code, feature, or design must obey. Article 1 is non-negotiable: **measurement accuracy comes first**, proven by tests. When articles conflict, the lower-numbered one wins.

## Status

🚧 **In active development.** The design phase is complete — product concept, constitution, data model, and detailed designs for the timing engine, score algorithm, and character voice are documented. Implementation follows a 4-week MVP plan (see [`docs/CONCEPT.md`](docs/CONCEPT.md) §7). No app code yet; this repository currently holds the design of record.

## Documentation

| Doc | What |
|-----|------|
| [`CONCEPT.md`](docs/CONCEPT.md) | What we're building, and why |
| [`CONSTITUTION.md`](docs/CONSTITUTION.md) | Top-level principles every decision obeys |
| [`data-model.md`](docs/data-model.md) | SwiftData schema (ERD) |
| [`tech-stack.md`](docs/tech-stack.md) | What we use, and why (by article) |
| [`timing-engine.md`](docs/timing-engine.md) | Millisecond timing & calibration design |
| [`score-algorithm.md`](docs/score-algorithm.md) | The explainable 0–100 Sae-do score |
| [`character-voice.md`](docs/character-voice.md) | Saechaan persona & trilingual copy |

## License

[MIT](LICENSE)
