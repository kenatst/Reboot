# REBOOT

**90 DAYS TO REBUILD YOUR ATTENTION.**

REBOOT is an adaptive attention-training system for iOS. It pairs a
90-day authored protocol with a deterministic behavioral engine that
learns from each user's actual sessions, environment actions, Flow
sessions, energy check-ins and experiments — then prescribes the next
best action.

> 90 days is the duration of the REBOOT program, not a universal
> biological reset duration. REBOOT does not diagnose, treat or make
> medical claims.

## Product architecture (V2)

The product loop is: DIAGNOSE → PRESCRIBE → MODIFY ENVIRONMENT → TRAIN →
APPLY TO REAL LIFE → MEASURE → ADAPT → REPEAT.

### AdaptiveRebootEngine

`Reboot/Engine/AdaptiveRebootEngine.swift` is the product brain. It takes
the AttentionProfile, program day, recent sessions, completed
interventions, experiments, required actions, energy check-in, Flow
projects and the curriculum day, and produces a `DailyPrescription`
(target, why, real-world action, training, flow window, recovery,
insight, difficulty, adaptation reason, fallback).

Decision logic is deterministic and explainable:

- Low energy after poor sleep → no duration increase, shorter session,
  recovery action.
- High reflex + weak environment → environment intervention, STAY,
  urge handling.
- High reflex or low stability → return/stability training.
- High stability + low recall → RECALL/EXPLAIN.
- Strong hobby flow + weak work stability → Flow conditions target.
- Repeatedly too-hard Flow tasks → smaller scope, shorter block.
- Failed required action → easier fallback, never a trap.

Every recommendation stores `adaptationReason`; DEBUG builds write an
`AdaptiveDecisionRecord` audit log.

### AttentionProfile

Eight dimensions — REFLEX, STABILITY, RETURN, RECALL, DEPTH, ENVIRONMENT,
ENERGY, FLOW — each with a qualitative value (UNKNOWN / LOW / MEDIUM /
HIGH / CALIBRATING), confidence, evidence count and source breakdown
(self-report / behavior / training / evaluation / environment). No
dimension is initialized with a fabricated numeric default.

### DailyPrescription

Persisted per day (`DailyPrescription`), composed of target, whyToday,
real-world action, training mode+duration, flow window, recovery action,
micro insight, difficulty, adaptation reason and fallback. Today renders
the prescription; the 90-day curriculum provides the progression
backbone.

### Environment interventions

`Reboot/Content/environment_interventions.json` — 60 authored
interventions across PHONE, NOTIFICATIONS, HOME SCREEN, WORKSPACE,
BROWSER, TABS, AUDIO, LOCATION, ROUTINE, MORNING, EVENING, SOCIAL MEDIA,
MESSAGING, SLEEP ENVIRONMENT. Each has a reason, steps, difficulty,
verification type, expected friction, fallback action and follow-up
question. `RequiredAction` gates progress only where meaningful; "JE N'AI
PAS PU" produces a lighter fallback.

### Flow Lab

`FlowProject` (goal, definition of done, feedback type), `FlowBuilderView`
(what are you doing / what does done mean / how will you see progress),
`FlowSessionView` (distraction contract + timer + 4 post-session
questions). REBOOT builds FLOW CONDITIONS — it never promises flow.

### Experiment engine

`Reboot/Content/experiments.json` — 40 test templates. `BehaviorExperiment`
records hypothesis, metric, status and a provisional result (KEEP / DROP /
INCONCLUSIVE). Conclusions use associational wording, never fabricated
causality.

### Energy / Fuel

`DailyEnergyCheckIn` stores self-reported energy, sleep, caffeine and best
window. `fuel_lessons.json` (8 lessons) covers energy, sleep, window,
caffeine observation, movement and recovery — with an explicit scope that
excludes medical advice, supplements, diets, fasting and sleep
deprivation protocols.

### 90-day curriculum

`Reboot/Content/daily_protocol.json` is the canonical authored 90-day
program (day, phase, week, mode, skill, title, intention, whyToday,
duration, difficulty, setup, instructions, challenge, reflection,
contentType, contentID, completionMessage). The adaptive engine chooses
the exact intervention on top of the curriculum.

## AI evaluation boundaries

`EvaluationProvider` remains remote-ready. The adaptive engine works
offline; when evaluation is unavailable the session is saved and no score
is invented. Evaluation payloads contain only session content, never
unrelated personal profile data. Clarity is a secondary internal signal
derived exclusively from real evaluation dimensions — it is not the
product and never a medical measure.

## Content validation

`Scripts/validate_content.py` checks JSON syntax, unique IDs, required
fields, content references, minimum counts, empty bodies, duplicates and
normalized similarity. Run before delivery.

## Building

```sh
xcodebuild -project Reboot.xcodeproj -scheme Reboot \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

DEBUG-only launch arguments (never in Release UI): `-uitest-skip-onboarding`,
`-Profile A…E`, `-EngineTests`, `-uitest-populated`, `-uitest-session …`.
