import Foundation

/// What the user is about to train.
struct SessionRequest: Identifiable {
    let id = UUID()
    let mode: SessionMode
    let day: Int
    let duration: Int
    let title: String
    let contentID: Int?
    var skipSetup = false
    var fastTimer = false
}

/// Builds a request for the current protocol day, or a free discipline.
enum SessionRequestFactory {
    static func discipline(
        _ mode: SessionMode,
        day: Int,
        recentContentIDs: [Int] = [],
        completedContentIDs: [Int] = []
    ) -> SessionRequest {
        let plan = ProtocolCurriculum.day(day)
        let context = ContentSelectionContext(
            mode: mode,
            targetSkill: plan.title,
            difficulty: 2,
            recentContentIDs: recentContentIDs,
            phase: plan.phase,
            completedContentIDs: completedContentIDs,
            day: day
        )
        let contentID = ContentSelector.select(context: context)
        let suggested = ProtocolEngine.suggestedDurations(for: mode, day: day).last ?? plan.recommendedDuration
        return SessionRequest(
            mode: mode,
            day: day,
            duration: suggested,
            title: plan.title,
            contentID: contentID
        )
    }

    /// THE canonical builder: the active DailyPrescription controls the
    /// session. The curriculum only describes the day's skill objective.
    static func prescription(
        prescription: DailyPrescription,
        curriculum: ProtocolDay,
        recentContentIDs: [Int] = [],
        completedContentIDs: [Int] = [],
        previousEvaluation: Double? = nil
    ) -> SessionRequest {
        let mode = SessionMode(rawValue: prescription.trainingMode) ?? curriculum.mode
        let context = ContentSelectionContext(
            mode: mode,
            targetSkill: prescription.primaryTarget,
            difficulty: prescription.difficulty,
            recentContentIDs: recentContentIDs,
            previousEvaluation: previousEvaluation,
            phase: prescription.phase,
            preferredCategories: [prescription.primaryTarget],
            completedContentIDs: completedContentIDs,
            day: curriculum.dayNumber
        )
        let contentID = ContentSelector.select(context: context)
        return SessionRequest(
            mode: mode,
            day: curriculum.dayNumber,
            duration: max(5, prescription.trainingDuration),
            title: curriculum.title,
            contentID: contentID
        )
    }
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

        // Exclude recently seen candidates if fresh candidates exist
        let freshCandidates = candidates.filter { !recentSet.contains($0.id) }
        let pool = freshCandidates.isEmpty ? candidates : freshCandidates

        // Score each candidate deterministically:
        let scored = pool.map { candidate -> (id: Int, score: Int) in
            var score = 0
            // 1. Correct target / preferred category
            if !context.preferredCategories.isEmpty && context.preferredCategories.contains(where: { candidate.category.localizedCaseInsensitiveContains($0) }) {
                score += 50
            } else if !context.targetSkill.isEmpty && candidate.category.localizedCaseInsensitiveContains(context.targetSkill) {
                score += 40
            }
            // 2. Correct difficulty
            if candidate.difficulty == targetDifficulty {
                score += 30
            } else if abs(candidate.difficulty - targetDifficulty) == 1 {
                score += 15
            }
            // 3. Not completed
            if !completedSet.contains(candidate.id) {
                score += 15
            }
            return (id: candidate.id, score: score)
        }

        // Priority ordering: highest score, tie-break deterministically by ID
        let sorted = scored.sorted { a, b in
            if a.score != b.score {
                return a.score > b.score
            }
            return a.id < b.id
        }
        return sorted.first?.id
    }

    private static func readingDifficulty(_ reading: ReadingExercise) -> Int {
        switch reading.length {
        case .short: return 1
        case .medium: return 2
        case .deep: return 3
        }
    }
}
