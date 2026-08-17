import Foundation

/// Strongly typed domain concepts. Raw values are persisted; French labels
/// are display-only.
enum GoalType: String, CaseIterable {
    case stopScrolling, work, study, readLonger, concentration, deepWork, learn, calmMind, lessPhone, discipline, other
    var fr: String { French.goalLabel(self) }
}

enum DistractorType: String, CaseIterable {
    case instagram, tiktok, youtube, x, reddit, whatsapp, messages, email, news, gaming, browser, workNotifications, other
    var fr: String { rawValue.capitalized }
}

enum EnergyLevel: String {
    case low = "Low", normal = "Normal", high = "High"
    var fr: String {
        switch self { case .low: return "Basse"; case .normal: return "Normale"; case .high: return "Haute" }
    }
}

enum SleepBucket: String, CaseIterable {
    case under5 = "<5", fiveSix = "5–6", sixSeven = "6–7", sevenEight = "7–8", eightPlus = "8+"
}

enum AttentionDimension: String, CaseIterable {
    case reflex, stability, retur, recall, depth, environment, flowConditions, energyContext
    var fr: String {
        switch self {
        case .reflex: return "RÉFLEXE"
        case .stability: return "STABILITÉ"
        case .retur: return "RETOUR"
        case .recall: return "RESTITUTION"
        case .depth: return "PROFONDEUR"
        case .environment: return "ENVIRONNEMENT"
        case .flowConditions: return "CONDITIONS DE FLOW"
        case .energyContext: return "CONTEXTE ÉNERGÉTIQUE"
        }
    }
}

enum EvidenceType: String {
    case selfReport = "SELF_REPORT"
    case sessionBehavior = "SESSION_BEHAVIOR"
    case interruption = "INTERRUPTION"
    case evaluation = "EVALUATION"
    case flowSession = "FLOW_SESSION"
    case environmentAction = "ENVIRONMENT_ACTION"
    case experiment = "EXPERIMENT"
    case energy = "ENERGY"
    case checkpoint = "CHECKPOINT"
    case realWorld = "REAL_WORLD_COMPLETION"
}

enum RequiredActionStatus: String {
    case pending, completed, failed, skipped
}

enum FailureReason: String, CaseIterable, Identifiable, Codable {
    case tooDifficult = "TROP DIFFICILE"
    case workNeed = "BESOIN POUR LE TRAVAIL"
    case familyNeed = "BESOIN POUR LA FAMILLE"
    case iosLimitation = "LIMITATION IOS"
    case notRelevant = "PAS PERTINENT"
    case forgot = "J'AI OUBLIÉ"
    case didNotWant = "JE NE VEUX PAS"
    case other = "AUTRE"

    var id: String { rawValue }
    var fr: String { rawValue }
}

enum ExperimentStatus: String {
    case proposed = "PROPOSED"
    case baseline = "BASELINE"
    case running = "RUNNING"
    case readyToReview = "READY_TO_REVIEW"
    case completed = "COMPLETED"
    case abandoned = "ABANDONED"
}

enum ExperimentOutcome: String {
    case inconclusive = "INCONCLUSIVE"
    case promising = "PROMISING"
    case kept = "KEPT"
    case dropped = "DROPPED"
}

enum ChallengeFit: String {
    case tooEasy = "TOO_EASY"
    case right = "RIGHT"
    case tooHard = "TOO_HARD"
    var fr: String {
        switch self {
        case .tooEasy: return "TROP FACILE"
        case .right: return "JUSTE"
        case .tooHard: return "TROP DUR"
        }
    }
}

enum FlowFeedbackType: String {
    case pages, questions, slides, tests, words, problems, custom
}

enum French {
    static func goalLabel(_ goal: GoalType) -> String {
        switch goal {
        case .stopScrolling: return "Arrêter de scroller automatiquement"
        case .work: return "Mieux travailler"
        case .study: return "Mieux étudier"
        case .readLonger: return "Lire plus longtemps"
        case .concentration: return "Retrouver de la concentration"
        case .deepWork: return "Faire du deep work"
        case .learn: return "Mieux apprendre"
        case .calmMind: return "Retrouver du calme mental"
        case .lessPhone: return "Moins dépendre du téléphone"
        case .discipline: return "Construire une vraie discipline"
        case .other: return "Autre"
        }
    }
}
