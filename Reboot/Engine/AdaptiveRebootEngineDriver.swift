import Foundation
import SwiftData

/// Persists the adaptive engine's outputs and manages V2 user state.
@MainActor
enum AdaptiveRebootEngineDriver {
    static func profile(context: ModelContext) -> RebootUserProfile? {
        (try? context.fetch(FetchDescriptor<RebootUserProfile>()))?.first
    }

    @discardableResult
    static func ensureProfile(context: ModelContext) -> RebootUserProfile {
        if let existing = profile(context: context) {
            return existing
        }
        let created = RebootUserProfile()
        context.insert(created)
        try? context.save()
        return created
    }

    static func prescription(forDay day: Int, context: ModelContext) -> DailyPrescription? {
        let descriptor = FetchDescriptor<DailyPrescription>(
            predicate: #Predicate { $0.day == day },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    /// Generates and persists the prescription for a program day using the
    /// adaptive engine. Deterministic and explainable.
    @discardableResult
    static func generatePrescription(forDay day: Int, context: ModelContext) -> DailyPrescription {
        if let existing = prescription(forDay: day, context: context) {
            return existing
        }
        let profile = ensureProfile(context: context)
        let sessions = (try? context.fetch(FetchDescriptor<TrainingSession>())) ?? []
        let interventions = (try? context.fetch(FetchDescriptor<CompletedIntervention>())) ?? []
        let experiments = (try? context.fetch(FetchDescriptor<BehaviorExperiment>())) ?? []
        let requiredActions = (try? context.fetch(FetchDescriptor<RequiredAction>())) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<DailyEnergyCheckIn>())) ?? []
        let flowProjects = (try? context.fetch(FetchDescriptor<FlowProject>())) ?? []
        let curriculum = ProtocolCurriculum.day(day)
        let attention = AttentionProfileBuilder.build(
            profile: profile,
            sessions: sessions,
            checkIns: checkIns
        )
        let plan = AdaptiveRebootEngine.prescribe(
            profile: attention,
            day: day,
            sessions: sessions,
            interventions: interventions,
            experiments: experiments,
            requiredActions: requiredActions,
            energyCheckIn: checkIns.last,
            flowProjects: flowProjects,
            curriculum: curriculum
        )

        let prescription = DailyPrescription(
            day: plan.day,
            phase: plan.phase,
            primaryTarget: plan.primaryTarget,
            whyToday: plan.whyToday,
            realWorldAction: plan.realWorldAction,
            trainingMode: plan.trainingMode,
            trainingDuration: plan.trainingDuration,
            flowWindow: plan.flowWindow,
            recoveryAction: plan.recoveryAction,
            microInsight: plan.microInsight,
            difficulty: plan.difficulty,
            adaptationReason: plan.adaptationReason,
            fallbackPlan: plan.fallbackPlan
        )
        context.insert(prescription)

        // Persist a required action when the prescription includes one.
        if !plan.realWorldAction.isEmpty {
            let action = RequiredAction(day: day, kind: "environment", title: plan.realWorldAction)
            context.insert(action)
        }

        #if DEBUG
        context.insert(AdaptiveDecisionRecord(day: day, summary: AdaptiveDebug.log(plan, profile: attention)))
        #endif
        try? context.save()
        return prescription
    }

    static func setRequiredActionDone(action: RequiredAction, context: ModelContext) {
        action.status = "completed"
        try? context.save()
    }

    static func setRequiredActionFailed(action: RequiredAction, reason: String, context: ModelContext) {
        action.status = "failed"
        action.blockReason = reason
        try? context.save()
    }

    static func recordEnergyCheckIn(energy: String, sleep: String, caffeine: String, window: String, context: ModelContext) {
        context.insert(DailyEnergyCheckIn(energy: energy, sleepHours: sleep, caffeine: caffeine, bestWindow: window))
        try? context.save()
    }

    static func recordSwitch(sessionID: UUID, elapsedSeconds: Int, kind: String, context: ModelContext) {
        context.insert(SessionInterruption(sessionID: sessionID, elapsedSeconds: elapsedSeconds, kind: kind))
        try? context.save()
    }

    static func completeIntervention(_ intervention: EnvironmentIntervention, outcome: String, context: ModelContext) {
        context.insert(CompletedIntervention(
            interventionID: intervention.id,
            title: intervention.title,
            category: intervention.category,
            outcome: outcome
        ))
        try? context.save()
    }

    static func startExperiment(template: ExperimentTemplate, context: ModelContext) {
        context.insert(BehaviorExperiment(
            templateID: template.id,
            title: template.title,
            hypothesis: template.hypothesis,
            metric: template.metric
        ))
        try? context.save()
    }

    static func activeExperiments(context: ModelContext) -> [BehaviorExperiment] {
        (try? context.fetch(FetchDescriptor<BehaviorExperiment>()))?
            .filter { $0.status == "active" } ?? []
    }
}
