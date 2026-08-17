import Foundation
import SwiftData

/// The origin that triggered this training session.
enum SessionOrigin: String, Codable {
    case `protocol`
    case freeTraining
    case explore
    case experiment
    case flow
}

/// What the user is about to train.
struct SessionRequest: Identifiable {
    let id = UUID()
    let mode: SessionMode
    let day: Int
    let duration: Int
    let title: String
    let contentID: Int?
    var origin: SessionOrigin = .protocol
    var advancesProtocol: Bool {
        origin == .protocol
    }
    var skipSetup = false
    var fastTimer = false
    var experimentID: UUID?
    var experimentCondition: String?
    var flowTaskID: UUID?
}

/// Context for deterministic, adaptive content selection.
struct ContentSelectionContext {
    var mode: SessionMode
    var targetSkill: String = ""
    var difficulty: Int = 2
    var recentContentIDs: [Int] = []
    var previousEvaluation: Double? = nil
    var phase: Int = 1
    var preferredCategories: [String] = []
    var completedContentIDs: [Int] = []
    var day: Int = 1
    var lastUsedTimestamps: [Int: Date] = [:]
}

/// Derives real session history and adaptive parameters for content selection.
@MainActor
enum ContentSelectionRepository {
    static func buildContext(
        mode: SessionMode,
        targetSkill: String,
        difficulty: Int,
        phase: Int,
        day: Int,
        preferredCategories: [String] = [],
        context: ModelContext
    ) -> ContentSelectionContext {
        var desc = FetchDescriptor<TrainingSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        desc.fetchLimit = 100
        let sessions = (try? context.fetch(desc)) ?? []
        let modeSessions = sessions.filter { $0.mode == mode }

        // Last 10 content IDs
        let recentContentIDs = Array(sessions.compactMap(\.contentID).prefix(10))
        let completedContentIDs = Array(Set(modeSessions.compactMap(\.contentID)))

        // Previous evaluation relevant to this discipline
        let evaluated = modeSessions.compactMap { $0.evaluation }
        let previousScore = evaluated.first?.overallScore
        let recentScores = evaluated.prefix(3).map(\.overallScore)

        // Adaptive difficulty derivation:
        var adaptedDifficulty = difficulty
        if mode == .recall {
            if recentScores.count >= 3 && recentScores.allSatisfy({ $0 >= 8.0 }) {
                adaptedDifficulty = min(3, difficulty + 1)
            } else if let prev = previousScore, prev <= 4.0 {
                adaptedDifficulty = max(1, difficulty - 1)
            }
        }

        // Context timestamps map for least-recently-used fallback
        var lastUsedDates: [Int: Date] = [:]
        for s in sessions {
            if let cid = s.contentID {
                if lastUsedDates[cid] == nil {
                    lastUsedDates[cid] = s.date
                }
            }
        }

        return ContentSelectionContext(
            mode: mode,
            targetSkill: targetSkill,
            difficulty: adaptedDifficulty,
            recentContentIDs: recentContentIDs,
            previousEvaluation: previousScore,
            phase: phase,
            preferredCategories: preferredCategories.isEmpty ? [targetSkill] : preferredCategories,
            completedContentIDs: completedContentIDs,
            day: day,
            lastUsedTimestamps: lastUsedDates
        )
    }
}

/// Builds a request for the current protocol day, or a free discipline.
enum SessionRequestFactory {
    @MainActor
    static func discipline(
        _ mode: SessionMode,
        day: Int,
        context: ModelContext? = nil
    ) -> SessionRequest {
        let plan = ProtocolCurriculum.day(day)
        let selectionContext: ContentSelectionContext
        if let context = context {
            selectionContext = ContentSelectionRepository.buildContext(
                mode: mode,
                targetSkill: plan.title,
                difficulty: 2,
                phase: plan.phase,
                day: day,
                context: context
            )
        } else {
            selectionContext = ContentSelectionContext(
                mode: mode,
                targetSkill: plan.title,
                difficulty: 2,
                phase: plan.phase,
                day: day
            )
        }
        let contentID = ContentSelector.select(context: selectionContext)
        let suggested = ProtocolEngine.suggestedDurations(for: mode, day: day).last ?? plan.recommendedDuration
        return SessionRequest(
            mode: mode,
            day: day,
            duration: suggested,
            title: plan.title,
            contentID: contentID,
            origin: .freeTraining
        )
    }

    /// THE canonical builder: the active DailyPrescription controls the
    /// session. The curriculum only describes the day's skill objective.
    @MainActor
    static func prescription(
        prescription: DailyPrescription,
        curriculum: ProtocolDay,
        context: ModelContext? = nil
    ) -> SessionRequest {
        let mode = SessionMode(rawValue: prescription.trainingMode) ?? curriculum.mode
        let selectionContext: ContentSelectionContext
        if let context = context {
            selectionContext = ContentSelectionRepository.buildContext(
                mode: mode,
                targetSkill: prescription.primaryTarget,
                difficulty: prescription.difficulty,
                phase: prescription.phase,
                day: curriculum.dayNumber,
                preferredCategories: [prescription.primaryTarget],
                context: context
            )
        } else {
            selectionContext = ContentSelectionContext(
                mode: mode,
                targetSkill: prescription.primaryTarget,
                difficulty: prescription.difficulty,
                phase: prescription.phase,
                preferredCategories: [prescription.primaryTarget],
                day: curriculum.dayNumber
            )
        }
        let contentID = ContentSelector.select(context: selectionContext)
        return SessionRequest(
            mode: mode,
            day: curriculum.dayNumber,
            duration: max(5, prescription.trainingDuration),
            title: curriculum.title,
            contentID: contentID,
            origin: .protocol
        )
    }
}

/// Adaptive content selection: selects deterministically by target skill,
/// difficulty, and freshness without pseudo-random modulo.
enum ContentSelector {
    static func select(context: ContentSelectionContext) -> Int? {
        switch context.mode {
        case .stay:
            return nil
        case .recall:
            let pool = ContentStore.readings
            guard !pool.isEmpty else { return nil }
            return selectBest(
                from: pool.map { (id: $0.id, category: $0.category, difficulty: readingDifficulty($0)) },
                context: context
            )
        case .explain:
            let pool = ContentStore.learningModules
            guard !pool.isEmpty else { return nil }
            return selectBest(
                from: pool.map { (id: $0.id, category: $0.topic, difficulty: 2) },
                context: context
            )
        case .observe:
            let pool = ContentStore.observationMissions
            guard !pool.isEmpty else { return nil }
            return selectBest(
                from: pool.map { (id: $0.id, category: $0.category, difficulty: 1) },
                context: context
            )
        case .nothing:
            let pool = ContentStore.voidPrompts
            guard !pool.isEmpty else { return nil }
            let recentSet = Set(context.recentContentIDs)
            let fresh = pool.filter { !recentSet.contains($0.id) }
            let candidatePool = fresh.isEmpty ? pool : fresh
            return candidatePool.sorted { $0.id < $1.id }.first?.id
        }
    }

    /// Legacy convenience wrapper mapping to ContentSelectionContext.
    static func select(mode: SessionMode, day: Int, difficulty: Int) -> Int? {
        let context = ContentSelectionContext(
            mode: mode,
            difficulty: difficulty,
            day: day
        )
        return select(context: context)
    }

    private static func selectBest(
        from candidates: [(id: Int, category: String, difficulty: Int)],
        context: ContentSelectionContext
    ) -> Int? {
        guard !candidates.isEmpty else { return nil }
        let recentSet = Set(context.recentContentIDs)
        let completedSet = Set(context.completedContentIDs)
        let targetDifficulty = (context.previousEvaluation != nil && (context.previousEvaluation ?? 10) < 5.0)
            ? max(1, context.difficulty - 1)
            : context.difficulty

        // 1. Exclude recently seen candidates (last 10) if fresh candidates exist
        let freshCandidates = candidates.filter { !recentSet.contains($0.id) }
        let pool = freshCandidates.isEmpty ? candidates : freshCandidates

        // Score each candidate deterministically:
        let scored = pool.map { candidate -> (id: Int, score: Int, lastUsed: Date) in
            var score = 0
            // Correct target / preferred category
            if !context.preferredCategories.isEmpty && context.preferredCategories.contains(where: { candidate.category.localizedCaseInsensitiveContains($0) }) {
                score += 50
            } else if !context.targetSkill.isEmpty && candidate.category.localizedCaseInsensitiveContains(context.targetSkill) {
                score += 40
            }
            // Correct difficulty
            if candidate.difficulty == targetDifficulty {
                score += 30
            } else if abs(candidate.difficulty - targetDifficulty) == 1 {
                score += 15
            }
            // Not completed before
            if !completedSet.contains(candidate.id) {
                score += 20
            }
            let lastDate = context.lastUsedTimestamps[candidate.id] ?? Date.distantPast
            return (id: candidate.id, score: score, lastUsed: lastDate)
        }

        // Priority ordering: highest score, then oldest-used date (LRU), then ID
        let sorted = scored.sorted { a, b in
            if a.score != b.score {
                return a.score > b.score
            }
            if a.lastUsed != b.lastUsed {
                return a.lastUsed < b.lastUsed
            }
            return a.id < b.id
        }
        return sorted.first?.id
    }

    private static func readingDifficulty(_ reading: ReadingExercise) -> Int {
        if let d = reading.difficulty { return d }
        switch reading.length {
        case .short: return 1
        case .medium: return 2
        case .deep: return 3
        }
    }
}

/// Evaluates baseline vs test observations for behavior experiments.
struct SessionComparator {
    struct ComparisonResult {
        var baselineCount: Int
        var testCount: Int
        var baselineFirstSwitchAvg: Double?
        var testFirstSwitchAvg: Double?
        var baselineSwitchesAvg: Double
        var testSwitchesAvg: Double
        var latencyDeltaSeconds: Double?
        var switchDelta: Double
        var isComparable: Bool
        var summaryNote: String
    }

    static func compare(observations: [ExperimentObservation]) -> ComparisonResult {
        let baseline = observations.filter { $0.condition == "BASELINE" }
        let test = observations.filter { $0.condition == "TEST" }

        guard baseline.count >= 3, test.count >= 3 else {
            return ComparisonResult(
                baselineCount: baseline.count,
                testCount: test.count,
                baselineFirstSwitchAvg: nil,
                testFirstSwitchAvg: nil,
                baselineSwitchesAvg: 0,
                testSwitchesAvg: 0,
                latencyDeltaSeconds: nil,
                switchDelta: 0,
                isComparable: false,
                summaryNote: "Données insuffisantes (3 sessions minimum par condition)."
            )
        }

        let baselineModes = Set(baseline.map(\.mode))
        let testModes = Set(test.map(\.mode))
        let commonModes = baselineModes.intersection(testModes)
        guard !commonModes.isEmpty else {
            return ComparisonResult(
                baselineCount: baseline.count,
                testCount: test.count,
                baselineFirstSwitchAvg: nil,
                testFirstSwitchAvg: nil,
                baselineSwitchesAvg: 0,
                testSwitchesAvg: 0,
                latencyDeltaSeconds: nil,
                switchDelta: 0,
                isComparable: false,
                summaryNote: "Échantillons non comparables (modes différents). Poursuis l'expérience sur le même mode."
            )
        }

        let baseFiltered = baseline.filter { commonModes.contains($0.mode) }
        let testFiltered = test.filter { commonModes.contains($0.mode) }

        let bSwitches = Double(baseFiltered.reduce(0) { $0 + $1.switchCount }) / Double(max(1, baseFiltered.count))
        let tSwitches = Double(testFiltered.reduce(0) { $0 + $1.switchCount }) / Double(max(1, testFiltered.count))

        let bLatencies = baseFiltered.compactMap(\.firstSwitchSeconds)
        let tLatencies = testFiltered.compactMap(\.firstSwitchSeconds)

        let bLatAvg = bLatencies.isEmpty ? nil : Double(bLatencies.reduce(0, +)) / Double(bLatencies.count)
        let tLatAvg = tLatencies.isEmpty ? nil : Double(tLatencies.reduce(0, +)) / Double(tLatencies.count)

        var latencyDelta: Double? = nil
        if let b = bLatAvg, let t = tLatAvg {
            latencyDelta = t - b
        }
        let switchDelta = tSwitches - bSwitches

        var note = ""
        if let latDelta = latencyDelta, latDelta > 60 {
            let mins = Int(latDelta / 60)
            let secs = Int(latDelta.truncatingRemainder(dividingBy: 60))
            note = "Dans tes sessions observées, ton premier réflexe de changement est retardé de +\(mins > 0 ? "\(mins)m " : "")\(secs)s (switches : \(String(format: "%.1f", bSwitches)) → \(String(format: "%.1f", tSwitches)))."
        } else if switchDelta < -0.5 {
            note = "Dans tes sessions observées, la fréquence de dispersion est réduite de \(String(format: "%.1f", bSwitches)) à \(String(format: "%.1f", tSwitches)) changements par session."
        } else {
            note = "Dans tes sessions observées, l'écart entre la ligne de base et le test reste modéré (\(String(format: "%.1f", bSwitches)) vs \(String(format: "%.1f", tSwitches)) changements)."
        }

        return ComparisonResult(
            baselineCount: baseFiltered.count,
            testCount: testFiltered.count,
            baselineFirstSwitchAvg: bLatAvg,
            testFirstSwitchAvg: tLatAvg,
            baselineSwitchesAvg: bSwitches,
            testSwitchesAvg: tSwitches,
            latencyDeltaSeconds: latencyDelta,
            switchDelta: switchDelta,
            isComparable: true,
            summaryNote: note
        )
    }
}

