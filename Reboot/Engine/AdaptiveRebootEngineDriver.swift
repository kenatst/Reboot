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
    /// adaptive engine. Deterministic, explainable and versioned: existing
    /// prescriptions are refreshed only when material evidence changes.
    @discardableResult
    static func generatePrescription(forDay day: Int, context: ModelContext) -> DailyPrescription {
        PrescriptionEngine.refreshIfNeeded(forDay: day, context: context)
        return prescription(forDay: day, context: context) ?? PrescriptionEngine.refreshIfNeeded(forDay: day, context: context)
    }

    static func refreshIfNeeded(forDay day: Int, context: ModelContext) {
        PrescriptionEngine.refreshIfNeeded(forDay: day, context: context)
    }

    /// Records structured evidence for the attention profile.
    static func recordEvidence(
        dimension: String,
        evidenceType: String,
        numericValue: Double? = nil,
        categoricalValue: String? = nil,
        sourceID: String? = nil,
        context: ModelContext
    ) {
        context.insert(AttentionEvidence(
            dimension: dimension,
            evidenceType: evidenceType,
            numericValue: numericValue,
            categoricalValue: categoricalValue,
            sourceID: sourceID
        ))
        try? context.save()
    }

    static func recordSessionEvidence(session: TrainingSession, context: ModelContext) {
        recordEvidence(
            dimension: "STABILITY",
            evidenceType: EvidenceType.sessionBehavior.rawValue,
            numericValue: Double(session.actualDurationSeconds / 60),
            categoricalValue: session.modeRaw,
            sourceID: session.id.uuidString,
            context: context
        )
        recordEvidence(
            dimension: "REFLEX",
            evidenceType: EvidenceType.interruption.rawValue,
            numericValue: Double(session.switchedCount),
            sourceID: session.id.uuidString,
            context: context
        )
        if let evaluation = session.evaluation {
            recordEvidence(
                dimension: "RECALL",
                evidenceType: EvidenceType.evaluation.rawValue,
                numericValue: evaluation.overallScore,
                sourceID: session.id.uuidString,
                context: context
            )
        }
    }

    static func recordEnergyEvidence(checkIn: DailyEnergyCheckIn, context: ModelContext) {
        recordEvidence(
            dimension: "ENERGY_CONTEXT",
            evidenceType: EvidenceType.energy.rawValue,
            categoricalValue: checkIn.energy,
            context: context
        )
    }

    static func recordInterventionEvidence(_ intervention: CompletedIntervention, context: ModelContext) {
        recordEvidence(
            dimension: "ENVIRONMENT",
            evidenceType: EvidenceType.environmentAction.rawValue,
            categoricalValue: "\(intervention.interventionID):\(intervention.outcome)",
            context: context
        )
    }

    static func recordFlowEvidence(_ session: FlowSession, context: ModelContext) {
        recordEvidence(
            dimension: "FLOW_CONDITIONS",
            evidenceType: EvidenceType.flowSession.rawValue,
            numericValue: Double(session.challengeRating),
            categoricalValue: session.lostTrackOfTime,
            context: context
        )
    }

    static func setRequiredActionDone(action: RequiredAction, context: ModelContext) {
        action.status = "completed"
        action.attemptCount += 1
        try? context.save()
    }

    static func setRequiredActionFailed(action: RequiredAction, reason: String, context: ModelContext) {
        action.status = "failed"
        action.failureReason = reason
        action.attemptCount += 1
        try? context.save()
    }

    static func recordEnergyCheckIn(energy: String, sleep: String, caffeine: String, window: String, context: ModelContext) {
        let checkIn = DailyEnergyCheckIn(energy: energy, sleepHours: sleep, caffeine: caffeine, bestWindow: window)
        context.insert(checkIn)
        recordEnergyEvidence(checkIn: checkIn, context: context)
        try? context.save()
    }

    static func recordSwitch(sessionID: UUID, elapsedSeconds: Int, kind: String, context: ModelContext) {
        context.insert(SessionInterruption(sessionID: sessionID, elapsedSeconds: elapsedSeconds, kind: kind))
        recordEvidence(
            dimension: "RETURN",
            evidenceType: EvidenceType.interruption.rawValue,
            numericValue: Double(elapsedSeconds),
            categoricalValue: kind,
            sourceID: sessionID.uuidString,
            context: context
        )
        try? context.save()
    }

    static func completeIntervention(_ intervention: EnvironmentIntervention, outcome: String, context: ModelContext) {
        let completed = CompletedIntervention(
            interventionID: intervention.id,
            title: intervention.title,
            category: intervention.category,
            outcome: outcome
        )
        context.insert(completed)
        recordInterventionEvidence(completed, context: context)
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

    /// Records a real observation for an active experiment from a tagged
    /// session and computes a provisional outcome once enough observations
    /// exist. Never lets the user claim "proven".
    static func recordExperimentObservation(experiment: BehaviorExperiment, session: TrainingSession, context: ModelContext) {
        guard experiment.status == "active" || experiment.status == "BASELINE" || experiment.status == "RUNNING" else { return }
        let interruptions = (try? context.fetch(FetchDescriptor<SessionInterruption>())) ?? []
        let firstSwitch = interruptions.first { $0.sessionID == session.id && $0.kind == "firstSwitch" }?.elapsedSeconds ?? -1
        let observation = "\(session.modeRaw)|\(session.actualDurationSeconds/60)|\(firstSwitch)|\(session.switchedCount)"
        experiment.observationsRaw.append(observation)
        let template = ContentStore.experimentTemplate(id: experiment.templateID)
        let minimum = template?.minimumSessions ?? 3
        if experiment.observationsRaw.count >= minimum {
            experiment.status = "READY_TO_REVIEW"
            evaluateExperiment(experiment)
        } else {
            experiment.status = experiment.observationsRaw.count >= 1 ? "RUNNING" : "BASELINE"
        }
        try? context.save()
    }

    private static func evaluateExperiment(_ experiment: BehaviorExperiment) {
        let observations = experiment.observationsRaw
        let switches = observations.map { Double($0.split(separator: "|")[3]) ?? 0 }
        let durations = observations.map { Double($0.split(separator: "|")[1]) ?? 0 }
        let averageSwitches = switches.reduce(0, +) / Double(max(1, switches.count))
        let averageDuration = durations.reduce(0, +) / Double(max(1, durations.count))
        // Provisional signal: lower switch density or longer durations under the
        // test condition. Associational wording only.
        let signal = averageSwitches <= 2 && averageDuration >= 20
        experiment.result = signal ? "PROMISING" : "INCONCLUSIVE"
        experiment.confidence = min(0.7, 0.4 + Double(observations.count) * 0.06)
        experiment.recommendation = signal
            ? "Dans tes sessions observées, cette condition était associée à un maintien plus long et moins de sorties."
            : "Observations insuffisantes pour conclure. Compare plus de sessions comparables."
    }

    /// A kept experiment or intervention becomes a personal rule.
    static func promoteToRule(title: String, source: String, context: ModelContext) {
        let rule = PersonalRule(rule: title, source: source)
        context.insert(rule)
        context.insert(AdaptationEvent(day: 0, kind: "RULE_CREATED", title: title, detail: source))
        try? context.save()
    }

    static func setRequiredActionFailed(action: RequiredAction, reason: FailureReason, context: ModelContext) {
        setRequiredActionFailed(action: action, reason: reason.rawValue, context: context)
    }

}
