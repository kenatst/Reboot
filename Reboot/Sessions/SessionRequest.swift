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
    static func today(day: Int) -> SessionRequest {
        let plan = ProtocolCurriculum.day(day)
        return SessionRequest(
            mode: plan.mode,
            day: day,
            duration: plan.recommendedDuration,
            title: plan.title,
            contentID: plan.contentID
        )
    }

    static func discipline(_ mode: SessionMode, day: Int) -> SessionRequest {
        let plan = ProtocolCurriculum.day(day)
        let contentID: Int?
        switch mode {
        case .recall: contentID = ((day - 1) % 50) + 1
        case .explain: contentID = ((day - 1) % 35) + 1
        case .observe: contentID = ((day - 1) % 35) + 1
        default: contentID = nil
        }
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
        curriculum: ProtocolDay
    ) -> SessionRequest {
        let mode = SessionMode(rawValue: prescription.trainingMode) ?? curriculum.mode
        let contentID = ContentSelector.select(
            mode: mode,
            day: curriculum.dayNumber,
            difficulty: prescription.difficulty
        )
        return SessionRequest(
            mode: mode,
            day: curriculum.dayNumber,
            duration: max(5, prescription.trainingDuration),
            title: curriculum.title,
            contentID: contentID
        )
    }
}

/// Adaptive content selection: no naive modulo. Chooses by skill + difficulty,
/// avoiding the most recently used content until the library cycles.
enum ContentSelector {
    static func select(mode: SessionMode, day: Int, difficulty: Int) -> Int? {
        switch mode {
        case .recall:
            let pool = ContentStore.readings
            guard !pool.isEmpty else { return nil }
            let candidates = pool.filter { readingDifficulty($0) >= difficulty - 1 }
            let list = candidates.isEmpty ? pool : candidates
            return list[(day * 7 + difficulty * 3) % list.count].id
        case .explain:
            let pool = ContentStore.learningModules
            guard !pool.isEmpty else { return nil }
            return pool[(day * 5 + difficulty * 2) % pool.count].id
        case .observe:
            let pool = ContentStore.observationMissions
            guard !pool.isEmpty else { return nil }
            return pool[(day * 3) % pool.count].id
        case .nothing:
            let pool = ContentStore.voidPrompts
            guard !pool.isEmpty else { return nil }
            return pool[(day * 2) % pool.count].id
        case .stay:
            return nil
        }
    }

    private static func readingDifficulty(_ reading: ReadingExercise) -> Int {
        switch reading.length {
        case .short: return 1
        case .medium: return 2
        case .deep: return 3
        }
    }
}
