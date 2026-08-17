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
        PrescriptionEngine.activePrescription(forDay: day, context: context)
    }

    /// Generates and persists the prescription for a program day using the
    /// adaptive engine. Deterministic, explainable and versioned: existing
    /// prescriptions are refreshed only when material evidence changes.
    @discardableResult
    static func generatePrescription(forDay day: Int, context: ModelContext) -> DailyPrescription {
        PrescriptionEngine.refreshIfNeeded(forDay: day, context: context)
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
        if let sourceID = sourceID {
            let all = (try? context.fetch(FetchDescriptor<AttentionEvidence>())) ?? []
            if let existing = all.first(where: { $0.sourceID == sourceID && $0.dimension == dimension && $0.evidenceType == evidenceType }) {
                existing.numericValue = numericValue
                existing.categoricalValue = categoricalValue
                existing.timestamp = .now
                try? context.save()
                return
            }
        }
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
        let actualMin = Double(session.actualDurationSeconds / 60)
        recordEvidence(
            dimension: "STABILITY",
            evidenceType: EvidenceType.sessionBehavior.rawValue,
            numericValue: actualMin,
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
        if (session.mode == .recall || session.mode == .explain), let evaluation = session.evaluation {
            recordEvidence(
                dimension: "RECALL",
                evidenceType: EvidenceType.evaluation.rawValue,
                numericValue: evaluation.overallScore,
                sourceID: session.id.uuidString,
                context: context
            )
        }
        if session.actualDurationSeconds / 60 >= 25 && session.switchedCount <= 2 {
            recordEvidence(
                dimension: "DEPTH",
                evidenceType: "DEEP_SESSION",
                numericValue: actualMin,
                sourceID: session.id.uuidString,
                context: context
            )
        }

        // Return evidence: only observed if user resumed and session ran >= 60 seconds after switch
        if session.switchedCount > 0 {
            let interruptions = (try? context.fetch(FetchDescriptor<SessionInterruption>()))?
                .filter { $0.sessionID == session.id } ?? []
            let returnObserved = interruptions.contains { interruption in
                let timeAfter = session.actualDurationSeconds - interruption.elapsedSeconds
                return timeAfter >= 60
            }
            if returnObserved {
                recordEvidence(
                    dimension: "RETURN",
                    evidenceType: "RETURN_AFTER_SWITCH",
                    categoricalValue: "RESUMED_SESSION",
                    sourceID: session.id.uuidString,
                    context: context
                )
            }
        }
        PrescriptionEngine.refreshIfNeeded(forDay: session.protocolDay, context: context)
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
            sourceID: intervention.id.uuidString,
            context: context
        )
    }

    static func recordFlowEvidence(_ session: FlowSession, context: ModelContext) {
        recordEvidence(
            dimension: "FLOW_CONDITIONS",
            evidenceType: EvidenceType.flowSession.rawValue,
            numericValue: Double(session.challengeRating),
            categoricalValue: "\(session.skillRating):\(session.lostTrackOfTime)",
            sourceID: session.id.uuidString,
            context: context
        )
    }

    static func setRequiredActionDone(action: RequiredAction, context: ModelContext) {
        action.status = "completed"
        action.attemptCount += 1
        try? context.save()
        PrescriptionEngine.refreshIfNeeded(forDay: action.day, context: context)
    }

    static func setRequiredActionFailed(action: RequiredAction, reason: String, context: ModelContext) {
        action.status = "failed"
        action.failureReason = reason
        action.attemptCount += 1
        try? context.save()
        PrescriptionEngine.refreshIfNeeded(forDay: action.day, context: context)
    }

    static func recordEnergyCheckIn(day: Int = 1, energy: String, sleep: String, caffeine: String, window: String, context: ModelContext) {
        let checkIn = DailyEnergyCheckIn(energy: energy, sleepHours: sleep, caffeine: caffeine, bestWindow: window)
        context.insert(checkIn)
        recordEnergyEvidence(checkIn: checkIn, context: context)
        try? context.save()
        PrescriptionEngine.refreshIfNeeded(forDay: day, context: context)
    }

    static func recordSwitch(sessionID: UUID, elapsedSeconds: Int, kind: String, context: ModelContext) {
        context.insert(SessionInterruption(sessionID: sessionID, elapsedSeconds: elapsedSeconds, kind: kind))
        if kind == "firstSwitch" || kind == "FIRST_SWITCH_LATENCY" {
            recordEvidence(
                dimension: "STABILITY",
                evidenceType: "FIRST_SWITCH_LATENCY",
                numericValue: Double(elapsedSeconds / 60),
                sourceID: sessionID.uuidString,
                context: context
            )
        } else {
            recordEvidence(
                dimension: "REFLEX",
                evidenceType: "interruption",
                numericValue: Double(elapsedSeconds),
                categoricalValue: kind,
                sourceID: sessionID.uuidString,
                context: context
            )
        }
        try? context.save()
    }

    static func completeIntervention(_ intervention: EnvironmentIntervention, day: Int = 1, outcome: String, context: ModelContext) {
        let completed = CompletedIntervention(
            interventionID: intervention.id,
            title: intervention.title,
            category: intervention.category,
            outcome: outcome
        )
        context.insert(completed)
        recordInterventionEvidence(completed, context: context)
        try? context.save()
        PrescriptionEngine.refreshIfNeeded(forDay: day, context: context)
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
            .filter { $0.status == "BASELINE" || $0.status == "RUNNING" || $0.status == "READY_TO_REVIEW" || $0.status == "active" } ?? []
    }

    /// Records a structured observation for an active experiment and computes
    /// baseline vs test outcome once >= 3 observations in each condition exist.
    static func recordExperimentObservation(
        experiment: BehaviorExperiment,
        session: TrainingSession,
        condition: String = "TEST",
        context: ModelContext
    ) {
        guard experiment.status == "BASELINE" || experiment.status == "RUNNING" || experiment.status == "PROPOSED" || experiment.status == "active" else { return }
        let interruptions = (try? context.fetch(FetchDescriptor<SessionInterruption>())) ?? []
        let firstSwitch = interruptions.first { $0.sessionID == session.id && ($0.kind == "firstSwitch" || $0.kind == "FIRST_SWITCH_LATENCY") }?.elapsedSeconds

        let observation = ExperimentObservation(
            experimentID: experiment.id,
            sessionID: session.id,
            condition: condition,
            mode: session.modeRaw,
            plannedDuration: session.plannedDurationSeconds / 60,
            actualDuration: session.actualDurationSeconds / 60,
            firstSwitchSeconds: firstSwitch,
            switchCount: session.switchedCount,
            energyContext: session.energy.map { "\($0)" } ?? "Normal",
            taskCategory: session.title
        )
        context.insert(observation)

        let rawStr = "\(condition)|\(session.modeRaw)|\(session.actualDurationSeconds/60)|\(firstSwitch ?? -1)|\(session.switchedCount)"
        experiment.observationsRaw.append(rawStr)

        evaluateExperiment(experiment, context: context)
        try? context.save()
        PrescriptionEngine.refreshIfNeeded(forDay: session.protocolDay, context: context)
    }

    static func evaluateExperiment(_ experiment: BehaviorExperiment, context: ModelContext) {
        let observations = (try? context.fetch(FetchDescriptor<ExperimentObservation>()))?
            .filter { $0.experimentID == experiment.id } ?? []

        let baseline = observations.filter { $0.condition == "BASELINE" }
        let test = observations.filter { $0.condition == "TEST" }

        let minBaseline = 3
        let minTest = 3

        if baseline.count < minBaseline {
            experiment.status = "BASELINE"
            experiment.currentCondition = "BASELINE"
            experiment.result = "inconclusive"
            experiment.recommendation = "En attente de \(minBaseline) sessions de baseline (actuel : \(baseline.count))."
            return
        }

        if test.count < minTest {
            experiment.status = "RUNNING"
            experiment.currentCondition = "TEST"
            experiment.result = "inconclusive"
            experiment.recommendation = "Baseline établie (\(baseline.count) sessions). En attente de \(minTest) sessions test (actuel : \(test.count))."
            return
        }

        experiment.status = "READY_TO_REVIEW"
        experiment.currentCondition = "TEST"
        let comparison = SessionComparator.compare(observations: observations)
        experiment.result = comparison.isComparable ? (comparison.switchDelta < -0.5 || (comparison.latencyDeltaSeconds ?? 0) > 60 ? "PROMISING" : "INCONCLUSIVE") : "INCONCLUSIVE"
        experiment.confidence = min(0.85, 0.4 + Double(baseline.count + test.count) * 0.05)
        experiment.recommendation = comparison.summaryNote
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
