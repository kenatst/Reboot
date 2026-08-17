import Foundation
import SwiftData

// MARK: - Attention profile

struct AttentionProfile {
    struct Dimension {
        let name: String
        let value: String       // UNKNOWN / LOW / MEDIUM / HIGH (qualitative)
        let confidence: Double  // 0...1
        let evidenceCount: Int
        let sources: [String]
    }

    var reflex: Dimension
    var stability: Dimension
    var retur: Dimension
    var recall: Dimension
    var depth: Dimension
    var environment: Dimension
    var energy: Dimension
    var flowReadiness: Dimension

    func dimension(_ name: String) -> Dimension? {
        switch name {
        case "REFLEX": return reflex
        case "STABILITY": return stability
        case "RETURN": return retur
        case "RECALL": return recall
        case "DEPTH": return depth
        case "ENVIRONMENT": return environment
        case "ENERGY": return energy
        case "FLOW": return flowReadiness
        default: return nil
        }
    }
}

/// Builds the attention profile from self-report (onboarding) plus real
/// behavioral evidence. Values are qualitative until evidence accumulates.
/// No dimension is ever initialized with a fabricated numeric default.
enum AttentionProfileBuilder {
    static func build(profile: RebootUserProfile?, sessions: [TrainingSession], checkIns: [DailyEnergyCheckIn]) -> AttentionProfile {
        // REFLEX: self-report switching + phone checking.
        let switching = Double(profile?.switchingFrequency ?? 0)
        let reflexValue: String = switching >= 4 ? "HIGH" : switching >= 2 ? "MEDIUM" : "LOW"
        let reflex = AttentionProfile.Dimension(
            name: "REFLEX",
            value: profile?.isCalibrated == true ? reflexValue : "CALIBRATING",
            confidence: profile?.isCalibrated == true ? 0.5 : 0,
            evidenceCount: profile?.isCalibrated == true ? 1 : 0,
            sources: profile?.isCalibrated == true ? ["SELF-REPORT"] : []
        )

        // STABILITY: real session durations + self-reported capacity.
        let staySessions = sessions.filter { $0.mode == .stay }
        let medianDuration = median(staySessions.map { Double($0.actualDurationSeconds / 60) })
        let stabilityValue: String
        if let medianDuration {
            stabilityValue = medianDuration >= 25 ? "HIGH" : medianDuration >= 12 ? "MEDIUM" : "LOW"
        } else {
            stabilityValue = profile?.isCalibrated == true ? "CALIBRATING" : "CALIBRATING"
        }
        let stability = AttentionProfile.Dimension(
            name: "STABILITY",
            value: stabilityValue,
            confidence: staySessions.count >= 3 ? 0.7 : 0.35,
            evidenceCount: staySessions.count,
            sources: staySessions.count >= 3 ? ["BEHAVIOR-DURATION"] : []
        )

        // RETURN: from interruption records.
        let returnValue: String = "CALIBRATING"
        let retur = AttentionProfile.Dimension(
            name: "RETURN",
            value: returnValue,
            confidence: 0,
            evidenceCount: 0,
            sources: []
        )

        // RECALL: real evaluations from recall/explain sessions.
        let evaluated = sessions.filter { $0.mode == .recall || $0.mode == .explain }
            .compactMap { $0.evaluation }
        let recallValue: String
        if evaluated.isEmpty {
            recallValue = profile?.isCalibrated == true ? "CALIBRATING" : "CALIBRATING"
        } else {
            let avg = evaluated.map(\.overallScore).reduce(0, +) / Double(evaluated.count)
            recallValue = avg >= 7 ? "HIGH" : avg >= 5 ? "MEDIUM" : "LOW"
        }
        let recall = AttentionProfile.Dimension(
            name: "RECALL",
            value: recallValue,
            confidence: evaluated.count >= 3 ? 0.7 : 0.3,
            evidenceCount: evaluated.count,
            sources: evaluated.isEmpty ? [] : ["EVALUATION"]
        )

        // DEPTH: longest session + challenge of deep sessions.
        let maxDuration = sessions.map { $0.actualDurationSeconds / 60 }.max()
        let depthValue: String
        if let maxDuration {
            depthValue = maxDuration >= 40 ? "HIGH" : maxDuration >= 20 ? "MEDIUM" : "LOW"
        } else {
            depthValue = "CALIBRATING"
        }
        let depth = AttentionProfile.Dimension(
            name: "DEPTH",
            value: depthValue,
            confidence: sessions.count >= 3 ? 0.6 : 0.3,
            evidenceCount: sessions.count,
            sources: sessions.isEmpty ? [] : ["BEHAVIOR-DURATION"]
        )

        // ENVIRONMENT: self-report only.
        let envValue: String
        switch profile?.phoneLocation ?? "" {
        case "in-hand", "desk": envValue = "WEAK"
        case "pocket", "nearby": envValue = "MEDIUM"
        case "another-room": envValue = "STRONG"
        default: envValue = "CALIBRATING"
        }
        let environment = AttentionProfile.Dimension(
            name: "ENVIRONMENT",
            value: envValue,
            confidence: profile?.isCalibrated == true ? 0.5 : 0,
            evidenceCount: profile?.isCalibrated == true ? 1 : 0,
            sources: profile?.isCalibrated == true ? ["SELF-REPORT"] : []
        )

        // ENERGY: latest self-report.
        let latest = checkIns.last
        let energy = AttentionProfile.Dimension(
            name: "ENERGY",
            value: latest?.energy ?? "CALIBRATING",
            confidence: latest != nil ? 0.5 : 0,
            evidenceCount: checkIns.count,
            sources: latest != nil ? ["SELF-REPORT"] : []
        )

        // FLOW readiness: existing flow activities + flow sessions.
        let hasFlowActivities = !(profile?.existingFlowActivitiesRaw ?? []).isEmpty
        let flow = AttentionProfile.Dimension(
            name: "FLOW",
            value: hasFlowActivities ? "STRONG IN CHOSEN ACTIVITIES" : "CALIBRATING",
            confidence: hasFlowActivities ? 0.5 : 0,
            evidenceCount: (profile?.existingFlowActivitiesRaw ?? []).count,
            sources: hasFlowActivities ? ["SELF-REPORT"] : []
        )

        return AttentionProfile(
            reflex: reflex,
            stability: stability,
            retur: retur,
            recall: recall,
            depth: depth,
            environment: environment,
            energy: energy,
            flowReadiness: flow
        )
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}

// MARK: - Prescription

struct PrescriptionPlan {
    let day: Int
    let phase: Int
    let primaryTarget: String
    let whyToday: String
    let realWorldAction: String
    let trainingMode: String
    let trainingDuration: Int
    let flowWindow: String
    let recoveryAction: String
    let microInsight: String
    let difficulty: Int
    let adaptationReason: String
    let fallbackPlan: String
}

// MARK: - Adaptive engine

/// Deterministic, explainable adaptive logic. Every recommendation stores why.
@MainActor
enum AdaptiveRebootEngine {
    static func prescribe(
        profile: AttentionProfile,
        day: Int,
        sessions: [TrainingSession],
        interventions: [CompletedIntervention],
        experiments: [BehaviorExperiment],
        requiredActions: [RequiredAction],
        energyCheckIn: DailyEnergyCheckIn?,
        flowProjects: [FlowProject],
        curriculum: ProtocolDay
    ) -> PrescriptionPlan {
        let plan = curriculum
        var reasons: [String] = []
        var targets: [String] = []
        var realWorldAction = plan.whyToday
        var trainingMode = plan.mode.rawValue
        var trainingDuration = plan.recommendedDuration
        var recoveryAction = ""
        var fallback = plan.setup.isEmpty ? "Réessaie demain." : plan.setup
        var flowWindow = ""
        let difficulty = plan.difficulty

        // 1. Energy gate: low energy after poor sleep never increases duration.
        let lowEnergy = energyCheckIn?.energy == "Low" || energyCheckIn?.sleepHours == "<5"
        if lowEnergy {
            trainingDuration = min(trainingDuration, 10)
            recoveryAction = "Énergie basse signalée : pas d'augmentation de durée aujourd'hui. Session courte, environnement allégé."
            reasons.append("energy=LOW")
        }

        // 2. Required action from previous prescription still pending/failed.
        if let pending = requiredActions.first(where: { $0.status == "pending" || $0.status == "failed" }) {
            realWorldAction = pending.title
            if pending.status == "failed" {
                fallback = "Action impossible ? Essaie la version plus légère : \(fallback)"
                reasons.append("requiredAction=\(pending.kind)/failed")
            } else {
                reasons.append("requiredAction=\(pending.kind)/pending")
            }
        }

        // 3. Reflex + weak environment → environment intervention + STAY.
        if profile.reflex.value == "HIGH", profile.environment.value == "WEAK" {
            targets.append("ENVIRONMENT")
            realWorldAction = realWorldAction.isEmpty ? "Intervention environnement : éloigne le téléphone de la table." : realWorldAction
            trainingMode = "stay"
            trainingDuration = min(trainingDuration, 12)
            reasons.append("reflex=HIGH environment=WEAK")
        } else if profile.reflex.value == "HIGH" || profile.stability.value == "LOW" {
            targets.append("STABILITY")
            trainingMode = "stay"
            trainingDuration = min(trainingDuration, 15)
            reasons.append(profile.reflex.value == "HIGH" ? "reflex=HIGH" : "stability=LOW")
        }

        // 4. Solid stability but weak recall → recall/explain.
        if profile.stability.value == "HIGH", profile.recall.value == "LOW" || profile.recall.value == "MEDIUM" {
            targets.append("RECALL")
            trainingMode = "recall"
            reasons.append("stability=HIGH recall=\(profile.recall.value)")
        }

        // 5. Strong hobby flow but weak work → flow conditions target.
        if profile.flowReadiness.value.hasPrefix("STRONG"), profile.stability.value == "LOW" || profile.stability.value == "MEDIUM" {
            targets.append("FLOW CONDITIONS")
            let project = flowProjects.first
            if let project {
                flowWindow = "FLOW WINDOW — \(project.title). Défini : \(project.definitionOfDone)."
            } else {
                flowWindow = "FLOW WINDOW — définis ce que « terminé » signifie avant de commencer."
            }
            reasons.append("hobbyFlow=strong workStability=\(profile.stability.value)")
        }

        // 6. Challenge calibration from flow sessions — only for sustained modes.
        if let project = flowProjects.first, trainingMode == "stay" || trainingMode == "recall" {
            let projectSessions = project.sessionsCompleted
            if projectSessions > 0, sessions.count >= 2 {
                // Too-hard signal: consecutive shorter sessions.
                let lastTwo = sessions.suffix(2).map { $0.actualDurationSeconds / 60 }
                if lastTwo.count == 2, lastTwo[0] > lastTwo[1] {
                    trainingDuration = trainingDuration > 12 ? max(10, trainingDuration - 5) : trainingDuration
                    fallback = "Tâche trop dure ? Réduis le périmètre : une étape plus petite, une fin plus claire."
                    reasons.append("flowChallenge=tooHard")
                } else if trainingDuration >= 15 {
                    trainingDuration += 5
                    reasons.append("flowChallenge=calibrated")
                }
            }
        }

        // 7. Experiment recommendation.
        let activeExperiments = experiments.filter { $0.status == "active" }
        if activeExperiments.isEmpty, profile.environment.value == "WEAK" || profile.reflex.value == "HIGH" {
            realWorldAction = realWorldAction + " Expérience suggérée : PHONE OUTSIDE ROOM pendant 3 sessions comparables."
            reasons.append("experiment=phoneOutsideRoom suggested")
        }

        if targets.isEmpty {
            targets.append("PROTOCOL")
            reasons.append("curriculum=\(plan.mode.rawValue)")
        }

        let primaryTarget = targets.first ?? "PROTOCOL"
        let whyToday = "\(plan.whyToday) — Aujourd'hui, le système cible \(primaryTarget)."
        let adaptationReason = reasons.joined(separator: " · ")
        let microInsight = ContentStore.microInsight(day: day)

        return PrescriptionPlan(
            day: day,
            phase: plan.phase,
            primaryTarget: primaryTarget,
            whyToday: whyToday,
            realWorldAction: realWorldAction,
            trainingMode: trainingMode,
            trainingDuration: trainingDuration,
            flowWindow: flowWindow,
            recoveryAction: recoveryAction,
            microInsight: microInsight,
            difficulty: difficulty,
            adaptationReason: adaptationReason,
            fallbackPlan: fallback
        )
    }
}

// MARK: - DEBUG decision log + profiles

#if DEBUG
@MainActor
enum AdaptiveDebug {
    static func log(_ plan: PrescriptionPlan, profile: AttentionProfile) -> String {
        """
        DAY \(plan.day) PRESCRIPTION
        PRIMARY TARGET: \(plan.primaryTarget)
        EVIDENCE: \(profile.stability.sources.joined(separator: ",")) stability=\(profile.stability.value) (\(profile.stability.evidenceCount) sessions)
        REAL-WORLD: \(plan.realWorldAction)
        TRAINING: \(plan.trainingMode.uppercased()) / \(plan.trainingDuration)m
        RECOVERY: \(plan.recoveryAction.isEmpty ? "—" : plan.recoveryAction)
        WHY: \(plan.adaptationReason)
        """
    }

    static func profile(name: String) -> RebootUserProfile {
        let p = RebootUserProfile()
        switch name {
        case "A":
            p.goalsRaw = ["arrêter de scroller automatiquement"]
            p.primaryGoal = "MOINS DÉPENDRE DU TÉLÉPHONE"
            p.primaryDistractor = "TikTok"
            p.checkMomentsRaw = ["réveil", "attente", "ennui"]
            p.capacityBucket = "10–20"
            p.returnDifficulty = 4
            p.readsTenPages = "Non"
            p.switchingFrequency = 5
            p.existingFlowActivitiesRaw = ["musique"]
            p.phoneLocation = "in-hand"
            p.notificationsLevel = "many"
            p.openTabsBucket = "20+"
            p.usesScreenTimeLimits = "Non"
            p.bestWindow = "morning"
            p.typicalSleep = "7–8"
            p.currentEnergy = "Normal"
            p.caffeine = "Morning only"
        case "B":
            p.goalsRaw = ["mieux travailler"]
            p.primaryGoal = "DEEP WORK"
            p.primaryDistractor = "Browser"
            p.checkMomentsRaw = ["pendant le travail"]
            p.capacityBucket = "45–60"
            p.returnDifficulty = 2
            p.readsTenPages = "Oui"
            p.switchingFrequency = 2
            p.existingFlowActivitiesRaw = ["coding"]
            p.phoneLocation = "another-room"
            p.notificationsLevel = "only important"
            p.openTabsBucket = "5–10"
            p.usesScreenTimeLimits = "Parfois"
            p.bestWindow = "late-morning"
            p.typicalSleep = "7–8"
            p.currentEnergy = "High"
            p.caffeine = "Morning + afternoon"
        case "C":
            p.goalsRaw = ["faire du deep work"]
            p.primaryGoal = "DEEP WORK"
            p.primaryDistractor = "Work notifications"
            p.capacityBucket = "45–60"
            p.returnDifficulty = 3
            p.readsTenPages = "Parfois"
            p.switchingFrequency = 3
            p.existingFlowActivitiesRaw = ["coding", "writing"]
            p.phoneLocation = "nearby"
            p.notificationsLevel = "many"
            p.openTabsBucket = "10–20"
            p.usesScreenTimeLimits = "Non"
            p.bestWindow = "morning"
            p.typicalSleep = "5–6"
            p.currentEnergy = "Low"
            p.caffeine = "Morning + afternoon"
        case "D":
            p.goalsRaw = ["retrouver de la concentration"]
            p.primaryGoal = "CONCENTRATION"
            p.primaryDistractor = "YouTube"
            p.capacityBucket = "10–20"
            p.returnDifficulty = 4
            p.readsTenPages = "Non"
            p.switchingFrequency = 4
            p.existingFlowActivitiesRaw = ["sport", "music"]
            p.phoneLocation = "desk"
            p.notificationsLevel = "many"
            p.openTabsBucket = "10–20"
            p.usesScreenTimeLimits = "Non"
            p.bestWindow = "evening"
            p.typicalSleep = "7–8"
            p.currentEnergy = "Normal"
            p.caffeine = "None"
        case "E":
            p.goalsRaw = ["mieux apprendre"]
            p.primaryGoal = "APPRENTISSAGE"
            p.primaryDistractor = "Reddit"
            p.capacityBucket = "45–60"
            p.returnDifficulty = 2
            p.readsTenPages = "Oui"
            p.switchingFrequency = 2
            p.existingFlowActivitiesRaw = ["reading", "coding"]
            p.phoneLocation = "another-room"
            p.notificationsLevel = "mostly disabled"
            p.openTabsBucket = "5"
            p.usesScreenTimeLimits = "Oui"
            p.bestWindow = "morning"
            p.typicalSleep = "7–8"
            p.currentEnergy = "High"
            p.caffeine = "Morning only"
        default:
            break
        }
        return p
    }
}
#endif
