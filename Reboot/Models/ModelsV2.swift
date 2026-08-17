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
}

struct FlowLesson: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let text: String
}

struct FuelLesson: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let text: String
    let scope: String
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

    // Distraction
    var primaryDistractor: String
    var checkMomentsRaw: [String]

    // Capacity
    var capacityBucket: String
    var returnDifficulty: Int
    var readsTenPages: String
    var switchingFrequency: Int

    // Flow
    var existingFlowActivitiesRaw: [String]
    var flowDifferenceRaw: [String]

    // Environment
    var phoneLocation: String
    var notificationsLevel: String
    var openTabsBucket: String
    var usesScreenTimeLimits: String

    // Energy
    var bestWindow: String
    var typicalSleep: String
    var currentEnergy: String
    var caffeine: String

    init() {
        self.id = UUID()
        self.createdAt = .now
        self.goalsRaw = []
        self.winDescription = ""
        self.primaryGoal = ""
        self.primaryDistractor = ""
        self.checkMomentsRaw = []
        self.capacityBucket = ""
        self.returnDifficulty = 0
        self.readsTenPages = ""
        self.switchingFrequency = 0
        self.existingFlowActivitiesRaw = []
        self.flowDifferenceRaw = []
        self.phoneLocation = ""
        self.notificationsLevel = ""
        self.openTabsBucket = ""
        self.usesScreenTimeLimits = ""
        self.bestWindow = ""
        self.typicalSleep = ""
        self.currentEnergy = ""
        self.caffeine = ""
    }

    var isCalibrated: Bool {
        !primaryGoal.isEmpty && !primaryDistractor.isEmpty && !capacityBucket.isEmpty
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
        fallbackPlan: String
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

    init(day: Int, kind: String, title: String) {
        self.id = UUID()
        self.day = day
        self.kind = kind
        self.title = title
        self.status = "pending"
        self.blockReason = ""
        self.createdAt = .now
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
    var status: String
    var baselineNote: String
    var result: String
    var confidence: Double
    var recommendation: String
    var startedAt: Date

    init(templateID: Int, title: String, hypothesis: String, metric: String) {
        self.id = UUID()
        self.templateID = templateID
        self.title = title
        self.hypothesis = hypothesis
        self.metric = metric
        self.status = "active"
        self.baselineNote = ""
        self.result = "inconclusive"
        self.confidence = 0
        self.recommendation = ""
        self.startedAt = .now
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

    init(title: String, definitionOfDone: String, feedbackType: String, goalClarity: Int = 0) {
        self.id = UUID()
        self.title = title
        self.definitionOfDone = definitionOfDone
        self.feedbackType = feedbackType
        self.goalClarity = goalClarity
        self.createdAt = .now
        self.sessionsCompleted = 0
    }
}

@Model
final class FlowSession {
    var id: UUID
    var projectID: UUID
    var durationSeconds: Int
    var challengeRating: Int
    var knewNextStep: Int
    var lostTrackOfTime: String
    var wantedToContinue: String
    var switchCount: Int
    var completed: Bool
    var createdAt: Date

    init(projectID: UUID, durationSeconds: Int) {
        self.id = UUID()
        self.projectID = projectID
        self.durationSeconds = durationSeconds
        self.challengeRating = 2
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
