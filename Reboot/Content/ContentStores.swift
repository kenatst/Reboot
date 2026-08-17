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

    static func reading(id: Int) -> ReadingExercise? {
        readings.first { $0.id == id }
    }

    static func learning(id: Int) -> LearningModule? {
        learningModules.first { $0.id == id }
    }

    static func mission(id: Int) -> ObservationMission? {
        observationMissions.first { $0.id == id }
    }
}
