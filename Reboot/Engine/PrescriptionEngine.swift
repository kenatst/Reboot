import Foundation
import SwiftData

/// Versioned prescription lifecycle. A prescription is only regenerated when
/// materially relevant evidence changes — never on every screen render.
@MainActor
enum PrescriptionEngine {
    static func activePrescription(forDay day: Int, context: ModelContext) -> DailyPrescription? {
        let descriptor = FetchDescriptor<DailyPrescription>(
            predicate: #Predicate { $0.day == day && $0.status == "active" },
            sortBy: [SortDescriptor(\.version, order: .reverse), SortDescriptor(\.generatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    /// Deterministic fingerprint of the material evidence that can change a plan.
    static func fingerprint(
        profile: RebootUserProfile?,
        sessions: [TrainingSession],
        interventions: [CompletedIntervention],
        experiments: [BehaviorExperiment],
        requiredActions: [RequiredAction],
        energyCheckIn: DailyEnergyCheckIn?,
        flowProjects: [FlowProject]
    ) -> String {
        var parts: [String] = []
        parts.append("p=\(profile?.isCalibrated == true ? 1 : 0)")
        if let profile {
            parts.append("dist=\(profile.primaryDistractor)")
            parts.append("cap=\(profile.capacityBucket)")
        }
        let recent = sessions.prefix(6)
        parts.append("s=\(recent.map { "\($0.modeRaw):\($0.actualDurationSeconds/60):\($0.switchedCount):\($0.evaluation?.overallScore ?? -1)" }.joined(separator: "|"))")
        parts.append("i=\(interventions.map { "\($0.interventionID):\($0.outcome)" }.joined(separator: "|"))")
        parts.append("e=\(experiments.map { "\($0.templateID):\($0.status)" }.joined(separator: "|"))")
        parts.append("a=\(requiredActions.map { "\($0.kind):\($0.status)" }.joined(separator: "|"))")
        if let energyCheckIn {
            parts.append("energy=\(energyCheckIn.energy)|\(energyCheckIn.sleepHours)")
        }
        parts.append("flow=\(flowProjects.count)")
        return parts.joined(separator: ";")
    }

    /// Refreshes the day's prescription only when the evidence fingerprint
    /// changed since generation. Supersedes older versions.
    @discardableResult
    static func refreshIfNeeded(forDay day: Int, context: ModelContext) -> DailyPrescription {
        let profile = AdaptiveRebootEngineDriver.ensureProfile(context: context)
        let sessions = (try? context.fetch(FetchDescriptor<TrainingSession>())) ?? []
        let interventions = (try? context.fetch(FetchDescriptor<CompletedIntervention>())) ?? []
        let experiments = (try? context.fetch(FetchDescriptor<BehaviorExperiment>())) ?? []
        let requiredActions = (try? context.fetch(FetchDescriptor<RequiredAction>())) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<DailyEnergyCheckIn>())) ?? []
        let flowProjects = (try? context.fetch(FetchDescriptor<FlowProject>())) ?? []

        let fingerprint = fingerprint(
            profile: profile,
            sessions: sessions,
            interventions: interventions,
            experiments: experiments,
            requiredActions: requiredActions,
            energyCheckIn: checkIns.last,
            flowProjects: flowProjects
        )

        if let active = activePrescription(forDay: day, context: context),
           active.evidenceFingerprint == fingerprint {
            return active
        }

        let existingActive = (try? context.fetch(FetchDescriptor<DailyPrescription>(
            predicate: #Predicate { $0.day == day && $0.status == "active" }
        ))) ?? []
        let previous = existingActive.max { $0.version < $1.version }

        let interruptions = (try? context.fetch(FetchDescriptor<SessionInterruption>())) ?? []
        let flowSessions = (try? context.fetch(FetchDescriptor<FlowSession>())) ?? []
        let attention = AttentionProfileBuilder.build(
            profile: profile,
            sessions: sessions,
            checkIns: checkIns,
            interruptions: interruptions,
            interventions: interventions,
            flowSessions: flowSessions
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
            curriculum: ProtocolCurriculum.day(day)
        )

        let nextVersion = (previous?.version ?? 0) + 1
        for old in existingActive {
            old.status = "superseded"
        }

        // Link the canonical RequiredAction
        let linkedAction: RequiredAction?
        if !plan.realWorldAction.isEmpty {
            if let existing = requiredActions.first(where: { $0.day == day && ($0.status == "pending" || $0.status == "failed") }) {
                linkedAction = existing
            } else {
                let created = RequiredAction(day: day, kind: "environment", title: plan.realWorldAction)
                context.insert(created)
                linkedAction = created
            }
        } else {
            linkedAction = nil
        }

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
            fallbackPlan: plan.fallbackPlan,
            version: nextVersion,
            evidenceFingerprint: fingerprint,
            adaptationNote: adaptationNote(previous: previous, plan: plan),
            requiredActionID: linkedAction?.id
        )
        context.insert(prescription)

        context.insert(AdaptationEvent(
            day: day,
            kind: "ADAPTATION",
            title: "PLAN V\(nextVersion)",
            detail: plan.adaptationReason
        ))
        #if DEBUG
        context.insert(AdaptiveDecisionRecord(day: day, summary: AdaptiveDebug.log(plan, profile: attention)))
        #endif
        try? context.save()
        return prescription
    }

    private static func adaptationNote(previous: DailyPrescription?, plan: PrescriptionPlan) -> String {
        guard let previous else { return "Première prescription du jour." }
        var parts: [String] = []
        if previous.trainingDuration != plan.trainingDuration {
            parts.append("Durée : \(previous.trainingDuration) → \(plan.trainingDuration) min")
        }
        if previous.trainingMode != plan.trainingMode {
            parts.append("Mode : \(previous.trainingMode.uppercased()) → \(plan.trainingMode.uppercased())")
        }
        if previous.primaryTarget != plan.primaryTarget {
            parts.append("Cible : \(previous.primaryTarget) → \(plan.primaryTarget)")
        }
        if parts.isEmpty {
            parts.append("Réglages inchangés (\(plan.adaptationReason)).")
        } else {
            parts.append("Raison : \(plan.adaptationReason).")
        }
        return parts.joined(separator: " ")
    }
}
