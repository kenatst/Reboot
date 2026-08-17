import Foundation

/// REBOOT V3 — Branching Adaptive Diagnosis Engine
/// Dynamically constructs an 8–14 question path based on user responses,
/// identifying goal branch, distraction triggers, capacity, absorption conditions,
/// and environment profile without generating fake scores.
enum DiagnosisQuestionEngine {
    enum QuestionKind: Equatable {
        case single(options: [String])
        case multi(options: [String])
        case text(placeholder: String, presets: [String])
        case slider(low: String, high: String)
    }

    struct Question: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
        let kind: QuestionKind
    }

    struct DiagnosisState {
        var selectedGoals: [String] = []
        var primaryGoal: String = ""
        var goalBranch: String = "general"

        // Branch answers
        var primaryDistractor: String = ""
        var triggerContext: String = ""
        var desiredOutcome: String = ""
        var workType: String = ""
        var workBreaker: String = ""
        var studyPurpose: String = ""
        var studyBottleneck: String = ""
        var canExplainCourse: String = ""
        var readingTarget: String = ""
        var readingFailureMode: String = ""

        // Common answers
        var capacityBucket: String = "10–20"
        var returnDifficulty: Int = 3
        var readsTenPages: String = "Parfois"
        var switchingFrequency: Int = 3
        var flowActivities: [String] = []
        var flowDifferences: [String] = []
        var phoneLocation: String = "desk"
        var notifications: String = "many"
        var tabs: String = "4–10"
        var bestWindow: String = "morning"
        var sleep: String = "7–8"
        var energy: String = "Normal"
        var caffeine: String = "Morning only"
    }

    // Step 0 options
    static let goalOptions = [
        "ARRÊTER DE SCROLLER",
        "MIEUX TRAVAILLER",
        "MIEUX ÉTUDIER",
        "LIRE PLUS",
        "APPRENDRE PLUS EFFICACEMENT",
        "RETROUVER DE LA CONCENTRATION",
        "FAIRE DU DEEP WORK",
        "CONSTRUIRE DU FLOW",
        "MOINS UTILISER MON TÉLÉPHONE",
        "RETROUVER DU CALME",
        "AUTRE"
    ]

    static func determineBranch(primaryGoal: String) -> String {
        let g = primaryGoal.uppercased()
        if g.contains("SCROLL") || g.contains("TÉLÉPHONE") || g.contains("MOINS UTILISER") {
            return "scroll"
        } else if g.contains("TRAVAILLER") || g.contains("DEEP WORK") {
            return "work"
        } else if g.contains("ÉTUDIER") || g.contains("APPRENDRE") {
            return "study"
        } else if g.contains("LIRE") {
            return "reading"
        } else {
            return "focus"
        }
    }

    static func buildQuestions(state: DiagnosisState) -> [Question] {
        var questions: [Question] = []

        // Q1: POURQUOI TU ES LÀ ?
        questions.append(Question(
            id: "goals",
            title: "POURQUOI TU ES LÀ ?",
            subtitle: "Sélectionne tout ce qui correspond à ta situation.",
            kind: .multi(options: goalOptions)
        ))

        // Q2: PRIMARY GOAL (single choice from selected goals or all if empty)
        let primaryOptions = state.selectedGoals.isEmpty ? goalOptions : state.selectedGoals
        questions.append(Question(
            id: "primaryGoal",
            title: "SI REBOOT NE POUVAIT EN RÉGLER QU'UN, LEQUEL ?",
            subtitle: "Ton objectif prioritaire pour les 90 prochains jours.",
            kind: .single(options: primaryOptions)
        ))

        let branch = determineBranch(primaryGoal: state.primaryGoal)

        switch branch {
        case "scroll":
            questions.append(Question(
                id: "scroll_app",
                title: "QUELLE APPLICATION T'ASPIRE LE PLUS ?",
                subtitle: "Ton piège attentionnel numéro un.",
                kind: .single(options: ["TikTok", "Instagram", "YouTube", "X (Twitter)", "Reddit", "Snapchat", "News", "Messages", "Autre"])
            ))
            questions.append(Question(
                id: "scroll_moments",
                title: "QUAND L'OUVRES-TU SANS VRAIMENT LE DÉCIDER ?",
                subtitle: "Les contextes réflexes.",
                kind: .single(options: ["Réveil", "Lit avant de dormir", "Pendant le travail", "Pendant les études", "Transports", "Ennui", "Temps d'attente", "Repas", "Toilettes", "Autre"])
            ))
            questions.append(Question(
                id: "scroll_outcome",
                title: "TON OBJECTIF RÉALISTE DANS 90 JOURS ?",
                subtitle: "Un changement comportemental précis.",
                kind: .text(placeholder: "Ex: Instagram ≤ 30 min/jour, pas de TikTok avant 18h…", presets: [
                    "Instagram ≤ 30 min / jour",
                    "Pas de réseaux avant 18h",
                    "Plus de téléphone au lit",
                    "Zéro scroll pendant les blocs de travail"
                ])
            ))

        case "work":
            questions.append(Question(
                id: "work_type",
                title: "QUEL TYPE DE TRAVAIL FAIS-TU ?",
                subtitle: "La nature de ton effort cognitif.",
                kind: .single(options: ["Écriture & Rédaction", "Code & Ingénierie", "Analyse & Données", "Gestion & Administration", "Créatif & Design", "Entrepreneuriat", "Autre"])
            ))
            questions.append(Question(
                id: "work_breaker",
                title: "QU'EST-CE QUI CASSE LE PLUS TES SESSIONS ?",
                subtitle: "Ton briseur de concentration principal.",
                kind: .single(options: ["Téléphone", "Messages & Slack", "Onglets du navigateur", "Emails", "Collègues & Interruptions", "Ennui & Friction", "Tâche trop floue", "Tâche trop difficile", "Fatigue"])
            ))
            questions.append(Question(
                id: "work_capacity",
                title: "COMBIEN DE TEMPS TIENS-TU ACTUELLEMENT ?",
                subtitle: "Sans aucune bascule.",
                kind: .single(options: ["< 10 min", "10–20 min", "20–30 min", "30–45 min", "45–60 min", "60+ min"])
            ))
            questions.append(Question(
                id: "work_outcome",
                title: "QU'EST-CE QUE 90 JOURS DEVRAIENT CHANGER ?",
                subtitle: "Ta cible de travail en profondeur.",
                kind: .text(placeholder: "Ex: 2 sessions de 60 min de deep work quotidien…", presets: [
                    "Travailler 60 min sans bascule",
                    "Fermer mes 30 onglets et rester sur une seule tâche",
                    "Terminer mes projets sans procrastination",
                    "Protéger mes matinées en focus complet"
                ])
            ))

        case "study":
            questions.append(Question(
                id: "study_purpose",
                title: "POUR QUOI ÉTUDIES-TU EN CE MOMENT ?",
                subtitle: "L'enjeu de tes révisions.",
                kind: .single(options: ["Concours ou Partiels", "Diplôme universitaire", "Certification professionnelle", "Apprentissage d'une langue", "Auto-formation continue", "Autre"])
            ))
            questions.append(Question(
                id: "study_bottleneck",
                title: "QUEL EST TON OBSTACLE MAJEUR ?",
                subtitle: "Où se situe la rupture.",
                kind: .single(options: ["Amorçage difficile (démarrer)", "Maintien difficile (rester assis)", "Compréhension floue (trop abstrait)", "Mémorisation faible (tout oublier après)"])
            ))
            questions.append(Question(
                id: "study_explain",
                title: "QUAND TU FERMES TON COURS, POURRAIS-TU L'EXPLIQUER ?",
                subtitle: "Test d'illusion de fluidité.",
                kind: .single(options: ["Oui, clairement avec mes mots", "En partie seulement", "Non, presque rien ne reste"])
            ))
            questions.append(Question(
                id: "study_capacity",
                title: "COMBIEN DE TEMPS RÉVISES-TU SANS ÉCRAN PARASITE ?",
                subtitle: "Ta fenêtre d'étude réelle.",
                kind: .single(options: ["< 10 min", "10–20 min", "20–30 min", "30–45 min", "45–60 min", "60+ min"])
            ))

        case "reading":
            questions.append(Question(
                id: "reading_target",
                title: "QUE VEUX-TU LIRE DAVANTAGE ?",
                subtitle: "Ton ambition de lecture.",
                kind: .single(options: ["Essais & Non-fiction", "Livres & Romans", "Articles de fond", "Documentation & Cours", "Philosophie & Idées"])
            ))
            questions.append(Question(
                id: "reading_mode",
                title: "QUE SE PASSE-T-IL D'HABITUDE ?",
                subtitle: "Le schéma de rupture de lecture.",
                kind: .single(options: ["Je vérifie mon téléphone", "Je relis sans retenir", "Mon esprit vagabonde", "Je m'ennuie rapidement", "Je m'endors", "J'abandonne après 5 pages"])
            ))
            questions.append(Question(
                id: "reading_ten_pages",
                title: "PEUX-TU LIRE 10 PAGES D'AFFILÉE AUJOURD'HUI ?",
                subtitle: "Sans aucune interruption.",
                kind: .single(options: ["Oui sans problème", "Parfois avec effort", "Non impossible"])
            ))

        default: // focus / calm
            questions.append(Question(
                id: "focus_breaker",
                title: "QU'EST-CE QUI VOLE TON ATTENTION ?",
                subtitle: "Ta source de dispersion principale.",
                kind: .single(options: ["Réseaux sociaux", "Messages constants", "Saut d'onglets", "Pensées parasites", "Fatigue générale", "Manque de structure"])
            ))
            questions.append(Question(
                id: "focus_capacity",
                title: "COMBIEN DE TEMPS PEUX-TU RESTER SUR UN SEUL OBJET ?",
                subtitle: "Sans distraction.",
                kind: .single(options: ["< 5 min", "5–10 min", "10–20 min", "20–30 min", "30–45 min", "45–60 min"])
            ))
        }

        // FLOW & ABSORPTION (All users)
        questions.append(Question(
            id: "flow_activities",
            title: "QU'EST-CE QUI TE FAIT DÉJÀ OUBLIER TON TÉLÉPHONE ?",
            subtitle: "Tes zones d'absorption naturelle existantes.",
            kind: .multi(options: ["Code & Programmation", "Jeux vidéo", "Sport & Entraînement", "Musique", "Dessin & Art", "Cuisine", "Lecture passion", "Discussion en direct", "Bricolage & Manuel", "Écriture", "Travail prenant", "Rien pour l'instant"])
        ))
        questions.append(Question(
            id: "flow_why",
            title: "POURQUOI CES ACTIVITÉS MARCHENT-ELLES ?",
            subtitle: "Les conditions de ton engagement profond.",
            kind: .multi(options: [
                "Je sais toujours quoi faire ensuite",
                "Je vois mes progrès immédiatement",
                "C'est un défi stimulant à mon niveau",
                "Personne ne m'interrompt",
                "Feedback instantané sur mes actions",
                "Physiquement ou sensoriellement impliqué",
                "J'aime profondément la matière"
            ])
        ))

        // ENVIRONMENT (Targeted)
        questions.append(Question(
            id: "env_phone",
            title: "OÙ SE TROUVE TON TÉLÉPHONE PENDANT LE TRAVAIL ?",
            subtitle: "Friction d'accès physique.",
            kind: .single(options: ["Dans la main ou sur les genoux", "Posé sur le bureau visible", "Dans la poche", "À proximité dans la pièce", "Dans une autre pièce"])
        ))
        questions.append(Question(
            id: "env_notifs",
            title: "QUEL EST LE RÉGLAGE DE TES NOTIFICATIONS ?",
            subtitle: "Signaux entrants.",
            kind: .single(options: ["Presque tout activé avec son/vibreur", "Beaucoup de bannières", "Seulement messages humains importants", "Presque tout désactivé"])
        ))

        if branch == "work" || branch == "study" {
            questions.append(Question(
                id: "env_tabs",
                title: "COMBIEN D'ONGLETS SONT OUVERTS EN GÉNÉRAL ?",
                subtitle: "Charge mentale de surface.",
                kind: .single(options: ["1–3 (très propre)", "4–10 (modéré)", "10–20 (surchargé)", "20+ (chaotique)"])
            ))
        }

        // ENERGY & ROUTINE
        questions.append(Question(
            id: "energy_window",
            title: "TA MEILLEURE FENÊTRE MENTALE ?",
            subtitle: "Quand ton esprit est le plus vif.",
            kind: .single(options: ["Matin tôt (06h–09h)", "Milieu de matinée (09h–12h)", "Début d'après-midi (14h–17h)", "Soirée (18h–22h)", "Variable selon les jours"])
        ))
        questions.append(Question(
            id: "energy_sleep",
            title: "SOMMEIL TYPIQUE PAR NUIT ?",
            subtitle: "La base biologique de l'attention.",
            kind: .single(options: ["< 5 heures", "5–6 heures", "6–7 heures", "7–8 heures", "8+ heures"])
        ))

        return questions
    }
}
