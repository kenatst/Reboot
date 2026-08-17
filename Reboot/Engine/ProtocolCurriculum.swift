import Foundation

enum ProtocolCurriculum {
    static let totalDays = 90

    /// Phase metadata lives in Swift; the 90-day program itself is authored
    /// content loaded from the canonical daily_protocol.json source.
    static let phases: [PhaseInfo] = [
        PhaseInfo(number: 1, title: "BREAK THE REFLEX", subtitle: "COUPER LE RÉFLEXE", range: 1...14),
        PhaseInfo(number: 2, title: "STABILIZE", subtitle: "STABILISER", range: 15...30),
        PhaseInfo(number: 3, title: "GO DEEPER", subtitle: "APPROFONDIR", range: 31...60),
        PhaseInfo(number: 4, title: "OWN IT", subtitle: "REPRENDRE LE CONTRÔLE", range: 61...90)
    ]

    private static let cachedDays: [ProtocolDay] = {
        guard let url = Bundle.main.url(forResource: "daily_protocol", withExtension: "json") else {
            return fail("daily_protocol.json is missing from the bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            let days = try JSONDecoder().decode([ProtocolDay].self, from: data)
            guard days.count == totalDays, days.map(\.dayNumber) == Array(1...totalDays) else {
                return fail("daily_protocol.json must contain exactly days 1...\(totalDays) in order.")
            }
            return days
        } catch {
            return fail("daily_protocol.json failed to decode: \(error)")
        }
    }()

    /// Fails loudly in DEBUG so authoring mistakes surface immediately.
    /// In RELEASE, returns a clearly-marked degraded grid instead of
    /// silently substituting generic content.
    private static func fail(_ message: String) -> [ProtocolDay] {
        #if DEBUG
        assertionFailure(message)
        #endif
        return (1...totalDays).map { day in
            let phaseInfo = phase(forDay: day)
            return ProtocolDay(
                dayNumber: day,
                phase: phaseInfo.number,
                week: min(13, (day - 1) / 7 + 1),
                mode: .stay,
                skill: "PROTOCOL CONTENT UNAVAILABLE",
                title: "PROTOCOL CONTENT UNAVAILABLE",
                intention: "Le programme quotidien n'a pas pu être chargé.",
                whyToday: "Réessaie après une mise à jour.",
                recommendedDuration: 10,
                difficulty: 1,
                setup: "",
                instructions: ["Le contenu du protocole est indisponible."],
                optionalChallenge: "",
                reflection: "",
                contentType: "none",
                contentID: nil,
                completionMessage: "SIGNAL PERDU — CONTENU INDISPONIBLE."
            )
        }
    }

    static func phase(forDay day: Int) -> PhaseInfo {
        phases.first { $0.range.contains(day) } ?? phases[0]
    }

    static func phase(forPhase number: Int) -> PhaseInfo {
        phases.first { $0.number == number } ?? phases[0]
    }

    /// Canonical authored 90-day curriculum.
    static let days: [ProtocolDay] = cachedDays

    static func day(_ number: Int) -> ProtocolDay {
        days[clamp(number, 1, totalDays) - 1]
    }

    static func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(upper, max(lower, value))
    }
}
