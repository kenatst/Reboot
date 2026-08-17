import Foundation
import SwiftData

// MARK: - Enums

enum SessionMode: String, Codable, CaseIterable, Identifiable {
    case stay
    case recall
    case explain
    case nothing
    case observe

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stay: return "STAY"
        case .recall: return "RECALL"
        case .explain: return "EXPLAIN"
        case .nothing: return "NOTHING"
        case .observe: return "OBSERVE"
        }
    }

    var frenchLabel: String {
        switch self {
        case .stay: return "CONCENTRATION"
        case .recall: return "LECTURE ACTIVE"
        case .explain: return "APPRENTISSAGE"
        case .nothing: return "VIDE"
        case .observe: return "BALADE ANALYTIQUE"
        }
    }

    var tagline: String {
        switch self {
        case .stay: return "UNE TÂCHE.\nRIEN D'AUTRE."
        case .recall: return "LIS.\nFERME.\nRECONSTRUIS."
        case .explain: return "APPRENDS.\nFERME.\nENSEIGNE."
        case .nothing: return "PAS DE\nNOUVEAU\nSTIMULUS."
        case .observe: return "REGARDE\nAVANT DE\nSCROLLER."
        }
    }

    var sessionBackground: SessionPalette {
        switch self {
        case .stay: return .void
        case .recall: return .bone
        case .explain: return .bone
        case .nothing: return .void
        case .observe: return .void
        }
    }
}

enum SessionPalette {
    case void
    case bone
}

enum ReadingLength: String, Codable, CaseIterable {
    case short
    case medium
    case deep

    var label: String {
        switch self {
        case .short: return "SHORT"
        case .medium: return "MEDIUM"
        case .deep: return "DEEP"
        }
    }
}

// MARK: - SwiftData models

@Model
final class TrainingSession {
    var id: UUID
    var date: Date
    var protocolDay: Int
    var phase: Int
    var modeRaw: String
    var title: String
    var intention: String
    var plannedDurationSeconds: Int
    var actualDurationSeconds: Int
    var task: String
    var sourceContent: String
    var userResponse: String
    var switchedCount: Int
    var calm: Int?
    var energy: Int?
    var completionOrdinal: Int
    var analysisAttempted: Bool
    var analysisOffline: Bool
    var evaluation: EvaluationResult?
    var restitution: Restitution?
    var experimentID: UUID?
    var experimentCondition: String?
    var contentID: Int?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        protocolDay: Int,
        phase: Int,
        mode: SessionMode,
        title: String,
        intention: String,
        plannedDurationSeconds: Int,
        task: String = "",
        sourceContent: String = "",
        userResponse: String = "",
        switchedCount: Int = 0,
        completionOrdinal: Int,
        contentID: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.protocolDay = protocolDay
        self.phase = phase
        self.modeRaw = mode.rawValue
        self.title = title
        self.intention = intention
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualDurationSeconds = 0
        self.task = task
        self.sourceContent = sourceContent
        self.userResponse = userResponse
        self.switchedCount = switchedCount
        self.completionOrdinal = completionOrdinal
        self.analysisAttempted = false
        self.analysisOffline = false
        self.contentID = contentID
    }

    var mode: SessionMode {
        get { SessionMode(rawValue: modeRaw) ?? .stay }
        set { modeRaw = newValue.rawValue }
    }

    var formattedDate: String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
            .uppercased()
    }
}

@Model
final class EvaluationResult {
    var id: UUID
    var sessionID: UUID
    var overallScore: Double
    var dimensions: [EvaluationDimension]
    var strength: String
    var mainGap: String
    var correction: String
    var nextChallenge: String
    var confidence: Double
    var insufficientEvidence: Bool
    var followUpQuestion: String?
    var provider: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        overallScore: Double,
        dimensions: [EvaluationDimension],
        strength: String,
        mainGap: String,
        correction: String,
        nextChallenge: String,
        confidence: Double,
        insufficientEvidence: Bool,
        followUpQuestion: String?,
        provider: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.overallScore = overallScore
        self.dimensions = dimensions
        self.strength = strength
        self.mainGap = mainGap
        self.correction = correction
        self.nextChallenge = nextChallenge
        self.confidence = confidence
        self.insufficientEvidence = insufficientEvidence
        self.followUpQuestion = followUpQuestion
        self.provider = provider
        self.createdAt = createdAt
    }
}

struct EvaluationDimension: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let score: Double
    let reason: String

    init(name: String, score: Double, reason: String) {
        self.name = name
        self.score = score
        self.reason = reason
    }
}

@Model
final class Restitution {
    var id: UUID
    var sessionID: UUID
    var kindRaw: String
    var text: String
    var wordCount: Int
    var createdAt: Date

    init(sessionID: UUID, kind: SessionMode, text: String, wordCount: Int, createdAt: Date = .now) {
        self.id = UUID()
        self.sessionID = sessionID
        self.kindRaw = kind.rawValue
        self.text = text
        self.wordCount = wordCount
        self.createdAt = createdAt
    }
}

@Model
final class RebootProgress {
    var id: UUID
    var currentDay: Int
    var completedSessions: Int
    var startedAt: Date?
    var lastSessionDate: Date?
    var coreModeUnlocked: Bool
    var checkpointsCompleted: Int

    init() {
        self.id = UUID()
        self.currentDay = 1
        self.completedSessions = 0
        self.coreModeUnlocked = false
        self.checkpointsCompleted = 0
    }
}

@Model
final class ProtocolDayCompletion {
    var id: UUID
    var dayNumber: Int
    var completedAt: Date
    var sessionID: UUID

    init(dayNumber: Int, completedAt: Date = .now, sessionID: UUID) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.completedAt = completedAt
        self.sessionID = sessionID
    }
}

@Model
final class WeeklyCheckpoint {
    var id: UUID
    var weekNumber: Int
    var completedAt: Date
    var biggestDistraction: String
    var easierNow: String
    var controlTarget: String
    var sessionsInWeek: Int

    init(
        weekNumber: Int,
        completedAt: Date = .now,
        biggestDistraction: String,
        easierNow: String,
        controlTarget: String,
        sessionsInWeek: Int
    ) {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.completedAt = completedAt
        self.biggestDistraction = biggestDistraction
        self.easierNow = easierNow
        self.controlTarget = controlTarget
        self.sessionsInWeek = sessionsInWeek
    }
}

@Model
final class SelfEvaluation {
    var id: UUID
    var sessionID: UUID
    var calm: Int
    var energy: Int
    var note: String
    var createdAt: Date

    init(sessionID: UUID, calm: Int, energy: Int, note: String = "", createdAt: Date = .now) {
        self.id = UUID()
        self.sessionID = sessionID
        self.calm = calm
        self.energy = energy
        self.note = note
        self.createdAt = createdAt
    }
}

@Model
final class ClaritySnapshot {
    var id: UUID
    var completedSessions: Int
    var statusRaw: String
    var snapshotDate: Date

    init(completedSessions: Int, statusRaw: String, snapshotDate: Date = .now) {
        self.id = UUID()
        self.completedSessions = completedSessions
        self.statusRaw = statusRaw
        self.snapshotDate = snapshotDate
    }
}

// MARK: - Content models (bundled, non-persisted)

struct ReadingExercise: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let category: String
    let length: ReadingLength
    let text: String
    var body: String?
    var centralThesis: String?
    var keyIdeas: [String]?
    var causalLinks: [String]?
    var examples: [String]?
    var question: String?
    var reconstructionPrompt: String?
    var transferPrompt: String?
    var difficulty: Int?
    var subtopic: String?

    var resolvedText: String {
        body ?? text
    }

    var resolvedQuestion: String {
        reconstructionPrompt ?? question ?? "Qu'est-ce qui est réellement resté ?"
    }

    var readingMinutes: Int {
        let words = resolvedText.split(whereSeparator: \.isWhitespace).count
        return max(1, Int((Double(words) / 220.0).rounded(.up)))
    }

    var wordCount: Int {
        resolvedText.split(whereSeparator: \.isWhitespace).count
    }
}

struct LearningModule: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let topic: String
    let text: String
    var hook: String?
    var coreIdea: String?
    var sections: [String]?
    var example: String?
    var counterExample: String?
    var commonMisconception: String?
    var application: String?
    var keyPoints: [String]?
    let teachBackPrompt: String
    var followUpPrompts: [String]?
    var difficulty: Int?

    var wordCount: Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    var readingMinutes: Int {
        max(1, Int((Double(wordCount) / 220.0).rounded(.up)))
    }
}

struct ObservationMission: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let category: String
    let mission: String
    let cues: [String]
    let reflection: String
}

struct VoidPrompt: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let prompt: String
    let durationMinutes: Int
    let context: String
}

struct MicroInsight: Codable, Identifiable, Hashable {
    let day: Int
    let text: String

    var id: Int { day }
}

struct WeeklyCheckpointTemplate: Codable, Identifiable, Hashable {
    let week: Int
    let title: String
    let insight: String
    let questions: [String]
    let objective: String

    var id: Int { week }
}

struct PhaseIntro: Codable, Identifiable, Hashable {
    let phase: Int
    let title: String
    let lines: [String]
    let body: String

    var id: Int { phase }
}

// MARK: - Protocol curriculum

struct ProtocolDay: Identifiable, Hashable, Codable {
    let dayNumber: Int
    let phase: Int
    let week: Int
    let mode: SessionMode
    let skill: String
    let title: String
    let intention: String
    let whyToday: String
    let recommendedDuration: Int
    let difficulty: Int
    let setup: String
    let instructions: [String]
    let optionalChallenge: String
    let reflection: String
    let contentType: String
    let contentID: Int?
    let completionMessage: String

    var id: Int { dayNumber }

    enum CodingKeys: String, CodingKey {
        case dayNumber = "day"
        case phase
        case week
        case mode
        case skill
        case title
        case intention
        case whyToday
        case recommendedDuration = "duration"
        case difficulty
        case setup
        case instructions
        case optionalChallenge = "challenge"
        case reflection
        case contentType
        case contentID
        case completionMessage
    }
}

struct PhaseInfo: Identifiable, Hashable {
    let number: Int
    let title: String
    let subtitle: String
    let range: ClosedRange<Int>

    var id: Int { number }

    var shortLabel: String {
        switch number {
        case 1: return "BREAK THE REFLEX"
        case 2: return "STABILIZE"
        case 3: return "GO DEEPER"
        default: return "OWN IT"
        }
    }
}
