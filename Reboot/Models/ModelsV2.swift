import Foundation
import SwiftData

// MARK: - V2 content structs (bundled, non-persisted)

struct EnvironmentIntervention: Codable, Identifiable, Hashable {
    let id: Int
    let category: String
    let title: String
    let reason: String
    let instructions: [String]
    let difficulty: Int
    let verificationType: String
    let expectedFriction: String
    let fallbackActionID: Int?
    let followUpQuestion: String
}

struct ExperimentTemplate: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let hypothesis: String
    let metric: String
    let testInstructions: [String]
    let minimumSessions: Int
    let category: String
}

struct MicroLesson: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let topic: String
    let text: String
    let action: String
    var hook: String?
    var example: String?
    var whatToNotice: String?
    var skills: [String]?
    var evidenceIDs: [String]?
    var estimatedMinutes: Int?
    var difficulty: Int?
}

struct FlowLesson: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let text: String
    var concept: String?
    var goodExample: String?
    var badExample: String?
    var exercise: String?
    var transferQuestion: String?
    var evidenceIDs: [String]?
}

struct FuelLesson: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let text: String
    let scope: String
    var takeaway: String?
    var experiment: String?
    var evidenceIDs: [String]?
}

struct CoachingMessage: Codable, Identifiable, Hashable {
    let id: Int
    let category: String
    let text: String
    var contextCondition: String?
}

struct ContentEvidenceRecord: Codable, Identifiable, Hashable {
    let id: String
    let topic: String
    let claim: String
    let sourceType: String
    let citation: String
    let url: String?
    let year: Int?
    let confidence: String
    let notes: String?
}

// MARK: - V2 SwiftData models

@Model
final class RebootUserProfile {
    var id: UUID
    var createdAt: Date

    // Goals
    var goalsRaw: [String]
    var winDescription: String
    var primaryGoal: String
    var goalBranch: String

    // Goal-specific branches
    var primaryDistractor: String
    var distractorTriggerContext: String
    var desiredOutcome: String
    var workType: String
    var workBreaker: String
    var studyPurpose: String
    var studyBottleneck: String
    var canExplainCourse: String
    var readingTarget: String
    var readingFailureMode: String

    // Distraction & Capacity
    var checkMomentsRaw: [String]
    var capacityBucket: String
    var returnDifficulty: Int
    var readsTenPages: String
    var switchingFrequency: Int

    // Flow & Absorption
    var existingFlowActivitiesRaw: [String]
    var flowDifferenceRaw: [String]
    var knownAbsorptionContext: String
    var flowConditionHypothesesRaw: [String]

    // Environment
    var phoneLocation: String
    var notificationsLevel: String
    var openTabsBucket: String
    var usesScreenTimeLimits: String

    // Energy & Preferences
    var bestWindow: String
    var typicalSleep: String
    var currentEnergy: String
    var caffeine: String
    var includeFuel: Bool
    var includeFlowLab: Bool
    var includeDigitalInterventions: Bool

    init() {
        self.id = UUID()
        self.createdAt = .now
        self.goalsRaw = []
        self.winDescription = ""
        self.primaryGoal = ""
        self.goalBranch = "general"
        self.primaryDistractor = ""
        self.distractorTriggerContext = ""
        self.desiredOutcome = ""
        self.workType = ""
        self.workBreaker = ""
        self.studyPurpose = ""
        self.studyBottleneck = ""
        self.canExplainCourse = ""
        self.readingTarget = ""
        self.readingFailureMode = ""
        self.checkMomentsRaw = []
        self.capacityBucket = "10–20"
        self.returnDifficulty = 3
        self.readsTenPages = ""
        self.switchingFrequency = 3
        self.existingFlowActivitiesRaw = []
        self.flowDifferenceRaw = []
        self.knownAbsorptionContext = ""
        self.flowConditionHypothesesRaw = []
        self.phoneLocation = "desk"
        self.notificationsLevel = "many"
        self.openTabsBucket = "4–10"
        self.usesScreenTimeLimits = "Non"
        self.bestWindow = "morning"
        self.typicalSleep = "7–8"
        self.currentEnergy = "Normal"
        self.caffeine = "Morning only"
        self.includeFuel = true
        self.includeFlowLab = true
        self.includeDigitalInterventions = true
    }

    var isCalibrated: Bool {
        !primaryGoal.isEmpty && (!primaryDistractor.isEmpty || !workBreaker.isEmpty || !studyBottleneck.isEmpty)
    }
}

@Model
final class AttentionDimensionState {
    var id: UUID
    var dimension: String
    var value: String
    var confidence: Double
    var evidenceCount: Int
    var updatedAt: Date
    var sourceBreakdownRaw: [String]

    init(dimension: String, value: String, confidence: Double, evidenceCount: Int, sourceBreakdown: [String] = []) {
        self.id = UUID()
        self.dimension = dimension
        self.value = value
        self.confidence = confidence
        self.evidenceCount = evidenceCount
        self.updatedAt = .now
        self.sourceBreakdownRaw = sourceBreakdown
    }
}

@Model
final class DailyPrescription {
    var id: UUID
    var day: Int
    var phase: Int
    var primaryTarget: String
    var whyToday: String
    var realWorldAction: String
    var actionStatus: String
    var trainingMode: String
    var trainingDuration: Int
    var flowWindow: String
    var recoveryAction: String
    var microInsight: String
    var difficulty: Int
    var adaptationReason: String
    var fallbackPlan: String
    var createdAt: Date
    var version: Int
    var generatedAt: Date
    var evidenceFingerprint: String
    var status: String
    var adaptationNote: String
    var requiredActionID: UUID?

    init(
        day: Int,
        phase: Int,
        primaryTarget: String,
        whyToday: String,
        realWorldAction: String,
        trainingMode: String,
        trainingDuration: Int,
        flowWindow: String,
        recoveryAction: String,
        microInsight: String,
        difficulty: Int,
        adaptationReason: String,
        fallbackPlan: String,
        version: Int = 1,
        evidenceFingerprint: String = "",
        adaptationNote: String = "",
        requiredActionID: UUID? = nil
    ) {
        self.id = UUID()
        self.day = day
        self.phase = phase
        self.primaryTarget = primaryTarget
        self.whyToday = whyToday
        self.realWorldAction = realWorldAction
        self.actionStatus = "pending"
        self.trainingMode = trainingMode
        self.trainingDuration = trainingDuration
        self.flowWindow = flowWindow
        self.recoveryAction = recoveryAction
        self.microInsight = microInsight
        self.difficulty = difficulty
        self.adaptationReason = adaptationReason
        self.fallbackPlan = fallbackPlan
        self.createdAt = .now
        self.version = version
        self.generatedAt = .now
        self.evidenceFingerprint = evidenceFingerprint
        self.status = "active"
        self.adaptationNote = adaptationNote
        self.requiredActionID = requiredActionID
    }
}

extension Collection where Element == DailyPrescription {
    /// Canonical accessor: exactly one active prescription per day.
    /// Picks status == "active", highest version, and newest generatedAt as tie-breaker.
    func activePrescription(forDay day: Int) -> DailyPrescription? {
        self.filter { $0.day == day && $0.status == "active" }
            .max { a, b in
                if a.version != b.version {
                    return a.version < b.version
                }
                return a.generatedAt < b.generatedAt
            }
    }
}

@Model
final class AdaptationEvent {
    var id: UUID
    var day: Int
    var kind: String
    var title: String
    var detail: String
    var createdAt: Date

    init(day: Int, kind: String, title: String, detail: String) {
        self.id = UUID()
        self.day = day
        self.kind = kind
        self.title = title
        self.detail = detail
        self.createdAt = .now
    }
}

@Model
final class AttentionEvidence {
    var id: UUID
    var timestamp: Date
    var dimension: String
    var evidenceType: String
    var numericValue: Double?
    var categoricalValue: String?
    var confidence: Double
    var sourceID: String?
    var metadata: String

    init(
        dimension: String,
        evidenceType: String,
        numericValue: Double? = nil,
        categoricalValue: String? = nil,
        confidence: Double = 0.6,
        sourceID: String? = nil,
        metadata: String = ""
    ) {
        self.id = UUID()
        self.timestamp = .now
        self.dimension = dimension
        self.evidenceType = evidenceType
        self.numericValue = numericValue
        self.categoricalValue = categoricalValue
        self.confidence = confidence
        self.sourceID = sourceID
        self.metadata = metadata
    }
}

struct ExperimentEligibility: Codable, Hashable {
    var allowedModes: [SessionMode]
    var taskCategory: String?
    var minimumDurationSeconds: Int?
    var projectID: UUID?

    static func forTemplate(templateID: Int, title: String) -> ExperimentEligibility {
        let t = title.uppercased()
        if t.contains("PHONE") || t.contains("TÉLÉPHONE") || t.contains("ROOM") || t.contains("PIÈCE") {
            return ExperimentEligibility(allowedModes: [.stay], minimumDurationSeconds: 10 * 60)
        }
        if t.contains("MUSIC") || t.contains("MUSIQUE") || t.contains("SILENCE") {
            return ExperimentEligibility(allowedModes: [.stay], minimumDurationSeconds: 10 * 60)
        }
        if t.contains("READ") || t.contains("LECTURE") || t.contains("LOCATION") || t.contains("LIEU") {
            return ExperimentEligibility(allowedModes: [.recall], minimumDurationSeconds: 5 * 60)
        }
        if t.contains("EXPLAIN") || t.contains("ENSEIGN") {
            return ExperimentEligibility(allowedModes: [.explain], minimumDurationSeconds: 5 * 60)
        }
        return ExperimentEligibility(allowedModes: [.stay], minimumDurationSeconds: 5 * 60)
    }

    func isEligible(mode: SessionMode, durationSeconds: Int, taskCategory: String? = nil, projectID: UUID? = nil) -> Bool {
        guard allowedModes.contains(mode) else { return false }
        if let minDur = minimumDurationSeconds, durationSeconds < minDur {
            return false
        }
        if let reqCat = self.taskCategory, let actualCat = taskCategory, !actualCat.localizedCaseInsensitiveContains(reqCat) {
            return false
        }
        if let reqProj = self.projectID, reqProj != projectID {
            return false
        }
        return true
    }
}

@Model
final class FlowTask {
    var id: UUID
    var projectID: UUID
    var taskTitle: String
    var definitionOfDone: String
    var challengeRatingBefore: Int
    var skillRatingBefore: Int
    var feedbackMechanism: String
    var distractionContract: String
    var plannedDurationSeconds: Int
    var actualDurationSeconds: Int
    var completionFraction: Double
    var switchCount: Int
    var createdAt: Date

    init(
        projectID: UUID,
        taskTitle: String,
        definitionOfDone: String,
        challengeRatingBefore: Int = 2,
        skillRatingBefore: Int = 2,
        feedbackMechanism: String = "étapes",
        distractionContract: String = "hors de la pièce",
        plannedDurationSeconds: Int = 25 * 60
    ) {
        self.id = UUID()
        self.projectID = projectID
        self.taskTitle = taskTitle
        self.definitionOfDone = definitionOfDone
        self.challengeRatingBefore = challengeRatingBefore
        self.skillRatingBefore = skillRatingBefore
        self.feedbackMechanism = feedbackMechanism
        self.distractionContract = distractionContract
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualDurationSeconds = 0
        self.completionFraction = 0
        self.switchCount = 0
        self.createdAt = .now
    }
}

@Model
final class RequiredAction {
    var id: UUID
    var day: Int
    var kind: String
    var title: String
    var status: String
    var blockReason: String
    var createdAt: Date
    var attemptCount: Int
    var failureReason: String
    var interventionID: Int?
    var verificationStrategy: String
    var requiredForProgress: Bool

    init(day: Int, kind: String, title: String) {
        self.id = UUID()
        self.day = day
        self.kind = kind
        self.title = title
        self.status = "pending"
        self.blockReason = ""
        self.createdAt = .now
        self.attemptCount = 0
        self.failureReason = ""
        self.interventionID = nil
        self.verificationStrategy = "MANUAL_CONFIRMATION"
        self.requiredForProgress = false
    }
}

@Model
final class CompletedIntervention {
    var id: UUID
    var interventionID: Int
    var title: String
    var category: String
    var completedAt: Date
    var outcome: String
    var followUpAnswer: String

    init(interventionID: Int, title: String, category: String, outcome: String = "kept") {
        self.id = UUID()
        self.interventionID = interventionID
        self.title = title
        self.category = category
        self.completedAt = .now
        self.outcome = outcome
        self.followUpAnswer = ""
    }
}

@Model
final class BehaviorExperiment {
    var id: UUID
    var templateID: Int
    var title: String
    var hypothesis: String
    var metric: String
    var status: String // PROPOSED, BASELINE, RUNNING, READY_TO_REVIEW, COMPLETED, ABANDONED
    var currentCondition: String // "BASELINE" or "TEST"
    var baselineNote: String
    var result: String
    var confidence: Double
    var recommendation: String
    var startedAt: Date
    var completedAt: Date?
    var observationsRaw: [String]

    init(templateID: Int, title: String, hypothesis: String, metric: String) {
        self.id = UUID()
        self.templateID = templateID
        self.title = title
        self.hypothesis = hypothesis
        self.metric = metric
        self.status = "BASELINE"
        self.currentCondition = "BASELINE"
        self.baselineNote = ""
        self.result = "inconclusive"
        self.confidence = 0
        self.recommendation = ""
        self.startedAt = .now
        self.completedAt = nil
        self.observationsRaw = []
    }
}

@Model
final class ExperimentObservation {
    var id: UUID
    var experimentID: UUID
    var sessionID: UUID
    var condition: String // "BASELINE" or "TEST"
    var mode: String
    var plannedDuration: Int
    var actualDuration: Int
    var firstSwitchSeconds: Int?
    var switchCount: Int
    var energyContext: String
    var taskCategory: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        experimentID: UUID,
        sessionID: UUID,
        condition: String,
        mode: String,
        plannedDuration: Int,
        actualDuration: Int,
        firstSwitchSeconds: Int? = nil,
        switchCount: Int = 0,
        energyContext: String = "Normal",
        taskCategory: String? = nil,
        timestamp: Date = .now
    ) {
        self.id = id
        self.experimentID = experimentID
        self.sessionID = sessionID
        self.condition = condition
        self.mode = mode
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.firstSwitchSeconds = firstSwitchSeconds
        self.switchCount = switchCount
        self.energyContext = energyContext
        self.taskCategory = taskCategory
        self.timestamp = timestamp
    }
}

@Model
final class FlowProject {
    var id: UUID
    var title: String
    var definitionOfDone: String
    var feedbackType: String
    var goalClarity: Int
    var createdAt: Date
    var sessionsCompleted: Int
    var category: String
    var whyItMatters: String
    var desiredOutcome: String
    var deadline: Date?
    var preferredWindow: String
    var skillEstimate: Int
    var defaultSessionLength: Int
    var defaultDistractionContract: String
    var active: Bool

    init(title: String, definitionOfDone: String, feedbackType: String, goalClarity: Int = 0) {
        self.id = UUID()
        self.title = title
        self.definitionOfDone = definitionOfDone
        self.feedbackType = feedbackType
        self.goalClarity = goalClarity
        self.createdAt = .now
        self.sessionsCompleted = 0
        self.category = "other"
        self.whyItMatters = ""
        self.desiredOutcome = ""
        self.deadline = nil
        self.preferredWindow = ""
        self.skillEstimate = 2
        self.defaultSessionLength = 25
        self.defaultDistractionContract = ""
        self.active = true
    }
}

@Model
final class FlowSession {
    var id: UUID
    var projectID: UUID
    var flowTaskID: UUID?
    var plannedDurationSeconds: Int
    var actualDurationSeconds: Int
    var challengeRating: Int
    var skillRating: Int
    var knewNextStep: Int
    var lostTrackOfTime: String
    var wantedToContinue: String
    var switchCount: Int
    var completed: Bool
    var createdAt: Date

    var durationSeconds: Int {
        get { actualDurationSeconds }
        set { actualDurationSeconds = newValue }
    }

    init(projectID: UUID, flowTaskID: UUID? = nil, plannedDurationSeconds: Int = 25 * 60, actualDurationSeconds: Int = 0) {
        self.id = UUID()
        self.projectID = projectID
        self.flowTaskID = flowTaskID
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
        self.challengeRating = 2
        self.skillRating = 2
        self.knewNextStep = 0
        self.lostTrackOfTime = ""
        self.wantedToContinue = ""
        self.switchCount = 0
        self.completed = false
        self.createdAt = .now
    }
}

@Model
final class DailyEnergyCheckIn {
    var id: UUID
    var date: Date
    var energy: String
    var sleepHours: String
    var caffeine: String
    var bestWindow: String

    init(energy: String, sleepHours: String, caffeine: String, bestWindow: String) {
        self.id = UUID()
        self.date = .now
        self.energy = energy
        self.sleepHours = sleepHours
        self.caffeine = caffeine
        self.bestWindow = bestWindow
    }
}

@Model
final class SessionInterruption {
    var id: UUID
    var sessionID: UUID
    var elapsedSeconds: Int
    var kind: String
    var createdAt: Date

    init(sessionID: UUID, elapsedSeconds: Int, kind: String) {
        self.id = UUID()
        self.sessionID = sessionID
        self.elapsedSeconds = elapsedSeconds
        self.kind = kind
        self.createdAt = .now
    }
}

@Model
final class PersonalRule {
    var id: UUID
    var rule: String
    var source: String
    var active: Bool
    var createdAt: Date

    init(rule: String, source: String) {
        self.id = UUID()
        self.rule = rule
        self.source = source
        self.active = true
        self.createdAt = .now
    }
}

@Model
final class AdaptiveDecisionRecord {
    var id: UUID
    var day: Int
    var summary: String
    var createdAt: Date

    init(day: Int, summary: String) {
        self.id = UUID()
        self.day = day
        self.summary = summary
        self.createdAt = .now
    }
}
