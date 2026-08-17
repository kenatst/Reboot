import Foundation

enum ProtocolCurriculum {
    static let totalDays = 90

    static let phases: [PhaseInfo] = [
        PhaseInfo(number: 1, title: "BREAK THE REFLEX", subtitle: "COUPER LE RÉFLEXE", range: 1...14),
        PhaseInfo(number: 2, title: "STABILIZE", subtitle: "STABILISER", range: 15...30),
        PhaseInfo(number: 3, title: "GO DEEPER", subtitle: "APPROFONDIR", range: 31...60),
        PhaseInfo(number: 4, title: "OWN IT", subtitle: "REPRENDRE LE CONTRÔLE", range: 61...90)
    ]

    static func phase(forDay day: Int) -> PhaseInfo {
        phases.first { $0.range.contains(day) } ?? phases[0]
    }

    static func phase(forPhase number: Int) -> PhaseInfo {
        phases.first { $0.number == number } ?? phases[0]
    }

    // Deterministic weekly rhythm per phase. The same cadence repeats inside
    // each phase so the training builds predictably instead of rotating at random.
    private static let rhythmPhase1: [SessionMode] = [.stay, .recall, .nothing, .stay, .observe, .recall, .stay]
    private static let rhythmPhase2: [SessionMode] = [.stay, .recall, .explain, .stay, .observe, .recall, .stay]
    private static let rhythmPhase3: [SessionMode] = [.stay, .recall, .explain, .nothing, .stay, .observe, .explain]
    private static let rhythmPhase4: [SessionMode] = [.stay, .explain, .recall, .stay, .observe, .explain, .stay]

    private static let stayTitles = [
        "UNE TÂCHE", "RESTER SUR UNE CHOSE", "LE MÊME OBJET", "UNE HEURE DE PRÉSENCE",
        "CONTINUER", "LE SEUL SUJET", "TENIR LA LIGNE", "REVENIR"
    ]
    private static let recallTitles = [
        "LIRE POUR RETENIR", "LA LECTURE ACTIVE", "LIRE ET RECONSTRUIRE", "LE TEXTE FERMÉ"
    ]
    private static let explainTitles = [
        "ENSEIGNER CE QUE TU VIENS D'APPRENDRE", "LA LEÇON FERMÉE", "EXPLIQUER SANS NOTES"
    ]
    private static let nothingTitles = [
        "NE RIEN FAIRE", "LE VIDE", "PAS DE NOUVEAU STIMULUS"
    ]
    private static let observeTitles = [
        "REGARDER AVANT DE SCROLLER", "LA BALADE ANALYTIQUE", "OBSERVER UN DÉTAIL"
    ]

    private static let stayIntentions = [
        "Rester sur une seule tâche sans changer.",
        "Entraîner le retour volontaire après une distraction.",
        "Prolonger légèrement la durée d'attention continue.",
        "Observer la pulsion de changement sans y céder."
    ]
    private static let recallIntentions = [
        "Lire un texte puis le reconstruire de mémoire.",
        "Apprendre à retenir l'essentiel sans surligner.",
        "Mesurer ce qui reste réellement après la lecture."
    ]
    private static let explainIntentions = [
        "Apprendre une notion puis l'enseigner sans support.",
        "Transformer une connaissance passive en explication active.",
        "Trouver les trous de compréhension en reformulant."
    ]
    private static let nothingIntentions = [
        "Passer du temps sans nouveau stimulus.",
        "Observer ce qui occupe l'esprit quand rien ne le nourrit.",
        "Réduire volontairement l'intensité de l'entrée."
    ]
    private static let observeIntentions = [
        "Observer le réel avant de consommer des images.",
        "Développer la patience du regard.",
        "Noter un détail que la vitesse habituelle cache."
    ]

    static let days: [ProtocolDay] = (1...totalDays).map { day in
        let phaseInfo = phase(forDay: day)
        let indexInPhase = day - phaseInfo.range.lowerBound
        let rhythm: [SessionMode]
        switch phaseInfo.number {
        case 1: rhythm = rhythmPhase1
        case 2: rhythm = rhythmPhase2
        case 3: rhythm = rhythmPhase3
        default: rhythm = rhythmPhase4
        }
        let mode = rhythm[indexInPhase % rhythm.count]

        let duration: Int
        switch phaseInfo.number {
        case 1:
            duration = mode == .nothing ? 5 : (mode == .observe ? 10 : 10)
        case 2:
            duration = mode == .nothing ? 8 : (mode == .observe ? 15 : 15)
        case 3:
            duration = mode == .nothing ? 10 : (mode == .observe ? 20 : 25)
        default:
            duration = mode == .nothing ? 12 : (mode == .observe ? 25 : 35)
        }

        let difficulty = min(5, 1 + (day - 1) / 9)

        let title: String
        let intention: String
        let instructions: [String]
        let challenge: String
        let contentID: Int?
        let variant = indexInPhase / rhythm.count

        switch mode {
        case .stay:
            title = stayTitles[(indexInPhase + variant) % stayTitles.count]
            intention = stayIntentions[(indexInPhase + variant) % stayIntentions.count]
            instructions = [
                "Choisis une seule tâche.",
                "Rien d'autre pendant \(duration) minutes.",
                "Si tu changes, note-le et reviens immédiatement."
            ]
            challenge = "Une seule vérification de téléphone pendant toute la session — pas plus."
            contentID = nil
        case .recall:
            title = recallTitles[(indexInPhase + variant) % recallTitles.count]
            intention = recallIntentions[(indexInPhase + variant) % recallIntentions.count]
            instructions = [
                "Lis le texte sans notes.",
                "Ferme-le.",
                "Reconstruis ce qui est resté, sans minimum de mots."
            ]
            challenge = "Après la restitution, relis une seule section qui a disparu."
            contentID = ((day - 1) % 50) + 1
        case .explain:
            title = explainTitles[(indexInPhase + variant) % explainTitles.count]
            intention = explainIntentions[(indexInPhase + variant) % explainIntentions.count]
            instructions = [
                "Apprends la leçon.",
                "Ferme-la.",
                "Enseigne-la comme à quelqu'un qui n'y connaît rien."
            ]
            challenge = "Trouve un contre-exemple de la notion et explique pourquoi il en est un."
            contentID = ((day - 1) % 35) + 1
        case .nothing:
            title = nothingTitles[(indexInPhase + variant) % nothingTitles.count]
            intention = nothingIntentions[(indexInPhase + variant) % nothingIntentions.count]
            instructions = [
                "Assieds-toi.",
                "Aucun stimulus nouveau.",
                "Laisse ce qui vient venir, sans l'attraper."
            ]
            challenge = "Après la session, attends une minute avant de toucher ton téléphone."
            contentID = nil
        case .observe:
            title = observeTitles[(indexInPhase + variant) % observeTitles.count]
            intention = observeIntentions[(indexInPhase + variant) % observeIntentions.count]
            instructions = [
                "Sors ou regarde par la fenêtre.",
                "Observe selon la mission du jour.",
                "Réponds à la question de réflexion sans chercher la bonne réponse."
            ]
            challenge = "Pendant l'observation, aucune photo, aucune note, aucun téléphone."
            contentID = ((day - 1) % 35) + 1
        }

        return ProtocolDay(
            dayNumber: day,
            phase: phaseInfo.number,
            mode: mode,
            title: title,
            intention: intention,
            recommendedDuration: duration,
            instructions: instructions,
            optionalChallenge: challenge,
            difficulty: difficulty,
            contentID: contentID
        )
    }

    static func day(_ number: Int) -> ProtocolDay {
        days[clamp(number, 1, totalDays) - 1]
    }

    static func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(upper, max(lower, value))
    }
}
