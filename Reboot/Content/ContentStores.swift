import Foundation

enum ContentError: LocalizedError {
    case missing(name: String)

    var errorDescription: String? {
        switch self {
        case .missing(let name):
            return "Bundled content \(name) could not be loaded."
        }
    }
}

/// Loads bundled educational content from JSON. All content is authored
/// original material; nothing is fabricated or attributed to fake researchers.
enum ContentStore {
    private static func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw ContentError.missing(name: name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    static var readings: [ReadingExercise] {
        (try? load("readings", as: [ReadingExercise].self)) ?? []
    }

    static var learningModules: [LearningModule] {
        (try? load("learnings", as: [LearningModule].self)) ?? []
    }

    static var observationMissions: [ObservationMission] {
        (try? load("missions", as: [ObservationMission].self)) ?? []
    }

    static var voidPrompts: [VoidPrompt] {
        (try? load("void_prompts", as: [VoidPrompt].self)) ?? []
    }

    static var microInsights: [MicroInsight] {
        (try? load("micro_insights", as: [MicroInsight].self)) ?? []
    }

    static var checkpoints: [WeeklyCheckpointTemplate] {
        (try? load("checkpoints", as: [WeeklyCheckpointTemplate].self)) ?? []
    }

    static var phaseIntros: [PhaseIntro] {
        (try? load("phase_intros", as: [PhaseIntro].self)) ?? []
    }

    static var environmentInterventions: [EnvironmentIntervention] {
        (try? load("environment_interventions", as: [EnvironmentIntervention].self)) ?? []
    }

    static var experimentTemplates: [ExperimentTemplate] {
        (try? load("experiments", as: [ExperimentTemplate].self)) ?? []
    }

    static var microLessons: [MicroLesson] {
        (try? load("micro_lessons", as: [MicroLesson].self)) ?? []
    }

    static var flowLessons: [FlowLesson] {
        (try? load("flow_lessons", as: [FlowLesson].self)) ?? []
    }

    static var fuelLessons: [FuelLesson] {
        (try? load("fuel_lessons", as: [FuelLesson].self)) ?? []
    }

    static func reading(id: Int) -> ReadingExercise? {
        readings.first { $0.id == id }
    }

    static func learning(id: Int) -> LearningModule? {
        learningModules.first { $0.id == id }
    }

    static func mission(id: Int) -> ObservationMission? {
        observationMissions.first { $0.id == id }
    }

    static func voidPrompt(id: Int) -> VoidPrompt? {
        voidPrompts.first { $0.id == id }
    }

    static func microInsight(day: Int) -> String {
        if let insight = microInsights.first(where: { $0.day == day }) {
            return insight.text
        }
        #if DEBUG
        assertionFailure("micro_insights.json is missing day \(day).")
        #endif
        return "SIGNAL BRIEF INDISPONIBLE"
    }

    static func checkpoint(week: Int) -> WeeklyCheckpointTemplate? {
        checkpoints.first { $0.week == week }
    }

    static func phaseIntro(phase: Int) -> PhaseIntro? {
        phaseIntros.first { $0.phase == phase }
    }

    static func environmentIntervention(id: Int) -> EnvironmentIntervention? {
        environmentInterventions.first { $0.id == id }
    }

    static func experimentTemplate(id: Int) -> ExperimentTemplate? {
        experimentTemplates.first { $0.id == id }
    }

    static func validateProtocolContent() -> Bool {
        #if DEBUG
        let days = ProtocolCurriculum.days
        guard days.count == 90 else {
            assertionFailure("daily_protocol.json must contain 90 days.")
            return false
        }
        return true
        #else
        return true
        #endif
    }
}
