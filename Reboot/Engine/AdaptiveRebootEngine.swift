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
    /// Canonical build method that consumes pure AttentionEvidence grouped by dimension.
    static func build(
        evidence: [AttentionEvidence],
        profile: RebootUserProfile?
    ) -> AttentionProfile {
        let byDim = Dictionary(grouping: evidence, by: { $0.dimension })

        // REFLEX: self-report switching + logged interruptions/urges.
        let reflexEv = byDim["REFLEX"] ?? []
        let urgeCount = reflexEv.filter { $0.evidenceType == "interruption" || $0.evidenceType == "REFLEX_EVENT" }.count
        let switching = Double(profile?.switchingFrequency ?? 0)
        let reflexValue: String
        if switching >= 4 || (switching >= 2 && urgeCount >= 2) {
            reflexValue = "HIGH"
        } else if switching >= 2 || urgeCount >= 3 {
            reflexValue = "MEDIUM"
        } else {
            reflexValue = "LOW"
        }
        let reflex = AttentionProfile.Dimension(
            name: "REFLEX",
            value: profile?.isCalibrated == true ? reflexValue : "CALIBRATING",
            confidence: min(0.9, 0.3 + Double(urgeCount) * 0.08 + (profile?.isCalibrated == true ? 0.2 : 0)),
            evidenceCount: urgeCount + (profile?.isCalibrated == true ? 1 : 0),
            sources: (profile?.isCalibrated == true ? ["SELF-REPORT"] : []) + (urgeCount > 0 ? ["INTERRUPTION"] : [])
        )

        // STABILITY: real session durations + first-switch latency + self-reported capacity.
        let stabilityEv = byDim["STABILITY"] ?? []
        let durationEv = stabilityEv.filter { $0.evidenceType == "sessionBehavior" || $0.evidenceType == "BEHAVIOR-DURATION" }.compactMap(\.numericValue)
        let firstSwitchEv = stabilityEv.filter { $0.evidenceType == "FIRST_SWITCH_LATENCY" }.compactMap(\.numericValue)
        let medianDuration = median(durationEv)
        let medianFirstSwitch = median(firstSwitchEv)
        let stabilityValue: String
        if let medianDuration, !durationEv.isEmpty {
            stabilityValue = medianDuration >= 25 ? "HIGH" : medianDuration >= 12 ? "MEDIUM" : "LOW"
        } else if let medianFirstSwitch, !firstSwitchEv.isEmpty {
            stabilityValue = medianFirstSwitch >= 15 ? "HIGH" : medianFirstSwitch >= 8 ? "MEDIUM" : "LOW"
        } else {
            switch profile?.capacityBucket ?? "" {
            case "60+", "45–60": stabilityValue = "HIGH"
            case "30–45", "20–30": stabilityValue = "MEDIUM"
            case "10–20", "5–10", "<5": stabilityValue = "LOW"
            default: stabilityValue = "CALIBRATING"
            }
        }
        let stability = AttentionProfile.Dimension(
            name: "STABILITY",
            value: stabilityValue,
            confidence: durationEv.count >= 3 ? 0.7 : min(0.5, Double(durationEv.count + firstSwitchEv.count) * 0.15),
            evidenceCount: durationEv.count + firstSwitchEv.count,
            sources: durationEv.count >= 3 ? ["BEHAVIOR-DURATION"] : (profile?.isCalibrated == true ? ["SELF-REPORT"] : [])
        )

        // RETURN: ONLY observed returns after a switch (RETURN_AFTER_SWITCH).
        // NEVER inferred from first-switch latency (which belongs to STABILITY).
        let returnEv = (byDim["RETURN"] ?? []).filter { $0.evidenceType == "RETURN_AFTER_SWITCH" }
        let returnValue: String
        let returnConfidence: Double
        let returnSources: [String]
        if returnEv.isEmpty {
            returnValue = "CALIBRATING"
            returnConfidence = 0.0
            returnSources = []
        } else {
            let resumedCount = returnEv.filter { $0.categoricalValue == "RESUMED_SESSION" }.count
            let totalReturns = returnEv.count
            let successRate = Double(resumedCount) / Double(totalReturns)
            if successRate >= 0.75 && totalReturns >= 3 {
                returnValue = "HIGH"
            } else if successRate >= 0.50 {
                returnValue = "MEDIUM"
            } else {
                returnValue = "LOW"
            }
            returnConfidence = min(0.85, 0.3 + Double(totalReturns) * 0.12)
            returnSources = ["RETURN_AFTER_SWITCH"]
        }
        let retur = AttentionProfile.Dimension(
            name: "RETURN",
            value: returnValue,
            confidence: returnConfidence,
            evidenceCount: returnEv.count,
            sources: returnSources
        )

        // RECALL: real evaluations from recall/explain sessions.
        let recallEv = (byDim["RECALL"] ?? []).filter { $0.evidenceType == "evaluation" }.compactMap(\.numericValue)
        let recallValue: String
        if recallEv.isEmpty {
            switch profile?.readsTenPages ?? "" {
            case "Oui": recallValue = "MEDIUM"
            case "Parfois": recallValue = "LOW"
            case "Non": recallValue = "LOW"
            default: recallValue = "CALIBRATING"
            }
        } else {
            let avg = recallEv.reduce(0, +) / Double(recallEv.count)
            recallValue = avg >= 7 ? "HIGH" : avg >= 5 ? "MEDIUM" : "LOW"
        }
        let recall = AttentionProfile.Dimension(
            name: "RECALL",
            value: recallValue,
            confidence: recallEv.count >= 3 ? 0.7 : 0.3,
            evidenceCount: recallEv.count,
            sources: recallEv.isEmpty ? (profile?.isCalibrated == true ? ["SELF-REPORT"] : []) : ["EVALUATION"]
        )

        // DEPTH: sustained, low-switch completed sessions — not just duration.
        let depthEv = (byDim["DEPTH"] ?? []).filter { $0.evidenceType == "DEEP_SESSION" }.compactMap(\.numericValue)
        let depthValue: String
        if !depthEv.isEmpty {
            let maxDuration = depthEv.max() ?? 0
            depthValue = maxDuration >= 45 ? "HIGH" : maxDuration >= 30 ? "MEDIUM" : "LOW"
        } else {
            depthValue = "CALIBRATING"
        }
        let depth = AttentionProfile.Dimension(
            name: "DEPTH",
            value: depthValue,
            confidence: depthEv.count >= 3 ? 0.6 : min(0.4, Double(depthEv.count) * 0.15),
            evidenceCount: depthEv.count,
            sources: depthEv.isEmpty ? [] : ["BEHAVIOR-DURATION"]
        )

        // ENVIRONMENT: self-report + completed interventions.
        let envEv = (byDim["ENVIRONMENT"] ?? []).filter { $0.evidenceType == "environmentAction" || $0.evidenceType == "ENVIRONMENT_ACTION" }
        let envValue: String
        if envEv.count >= 3 {
            envValue = "STRONG"
        } else if envEv.count >= 1 {
            envValue = "MEDIUM"
        } else {
            switch profile?.phoneLocation ?? "" {
            case "in-hand", "desk": envValue = "WEAK"
            case "pocket", "nearby": envValue = "MEDIUM"
            case "another-room": envValue = "STRONG"
            default: envValue = "CALIBRATING"
            }
        }
        let environment = AttentionProfile.Dimension(
            name: "ENVIRONMENT",
            value: envValue,
            confidence: min(0.8, 0.3 + Double(envEv.count) * 0.15 + (profile?.isCalibrated == true ? 0.2 : 0)),
            evidenceCount: envEv.count + (profile?.isCalibrated == true ? 1 : 0),
            sources: (profile?.isCalibrated == true ? ["SELF-REPORT"] : []) + (envEv.count > 0 ? ["ENVIRONMENT_ACTION"] : [])
        )

        // ENERGY: latest self-report.
        let energyEv = byDim["ENERGY_CONTEXT"] ?? byDim["ENERGY"] ?? []
        let latestEnergy = energyEv.last?.categoricalValue
        let energy = AttentionProfile.Dimension(
            name: "ENERGY",
            value: latestEnergy ?? "CALIBRATING",
            confidence: latestEnergy != nil ? 0.5 : 0,
            evidenceCount: energyEv.count,
            sources: latestEnergy != nil ? ["SELF-REPORT"] : []
        )

        // FLOW CONDITIONS: known absorption contexts + observed conditions.
        let flowEv = byDim["FLOW_CONDITIONS"] ?? byDim["FLOW"] ?? []
        let hasFlowActivities = !(profile?.existingFlowActivitiesRaw ?? []).isEmpty
        let flowObservations = flowEv.count
        let flow = AttentionProfile.Dimension(
            name: "FLOW",
            value: flowObservations >= 3 ? "MEDIUM" : (hasFlowActivities ? "KNOWN CONTEXTS" : "CALIBRATING"),
            confidence: min(0.8, Double(flowObservations) * 0.2 + (hasFlowActivities ? 0.2 : 0)),
            evidenceCount: flowObservations + (profile?.existingFlowActivitiesRaw ?? []).count,
            sources: (hasFlowActivities ? ["SELF-REPORT"] : []) + (flowObservations > 0 ? ["FLOW_SESSION"] : [])
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

    /// Convenience wrapper transforming raw entities into AttentionEvidence and delegating to canonical builder.
    static func build(
        profile: RebootUserProfile?,
        sessions: [TrainingSession],
        checkIns: [DailyEnergyCheckIn],
        interruptions: [SessionInterruption] = [],
        interventions: [CompletedIntervention] = [],
        flowSessions: [FlowSession] = []
    ) -> AttentionProfile {
        var evidenceList: [AttentionEvidence] = []

        // Interruptions -> REFLEX & STABILITY (FIRST_SWITCH_LATENCY)
        for i in interruptions {
            if i.kind == "interruption" || i.kind == "REFLEX_EVENT" {
                evidenceList.append(AttentionEvidence(dimension: "REFLEX", evidenceType: "interruption", numericValue: Double(i.elapsedSeconds)))
            } else if i.kind == "firstSwitch" || i.kind == "FIRST_SWITCH_LATENCY" {
                evidenceList.append(AttentionEvidence(dimension: "STABILITY", evidenceType: "FIRST_SWITCH_LATENCY", numericValue: Double(i.elapsedSeconds / 60)))
            }
        }

        // Sessions -> STABILITY, RECALL, DEPTH, and RETURN (if switch happened and session completed)
        for s in sessions {
            let actualMin = Double(s.actualDurationSeconds / 60)
            if s.mode == .stay {
                evidenceList.append(AttentionEvidence(dimension: "STABILITY", evidenceType: "sessionBehavior", numericValue: actualMin))
            }
            if (s.mode == .recall || s.mode == .explain), let eval = s.evaluation {
                evidenceList.append(AttentionEvidence(dimension: "RECALL", evidenceType: "evaluation", numericValue: eval.overallScore))
            }
            if s.actualDurationSeconds / 60 >= 25 && s.switchedCount <= 2 {
                evidenceList.append(AttentionEvidence(dimension: "DEPTH", evidenceType: "DEEP_SESSION", numericValue: actualMin))
            }
            // RETURN evidence: user switched and completed session
            if s.switchedCount > 0 && s.actualDurationSeconds > 60 {
                evidenceList.append(AttentionEvidence(dimension: "RETURN", evidenceType: "RETURN_AFTER_SWITCH", categoricalValue: "RESUMED_SESSION"))
            }
        }

        // Interventions -> ENVIRONMENT
        for iv in interventions {
            evidenceList.append(AttentionEvidence(dimension: "ENVIRONMENT", evidenceType: "environmentAction", categoricalValue: "\(iv.interventionID):\(iv.outcome)"))
        }

        // Check-ins -> ENERGY_CONTEXT
        for ci in checkIns {
            evidenceList.append(AttentionEvidence(dimension: "ENERGY_CONTEXT", evidenceType: "energy", categoricalValue: ci.energy))
        }

        // FlowSessions -> FLOW_CONDITIONS
        for fs in flowSessions {
            evidenceList.append(AttentionEvidence(dimension: "FLOW_CONDITIONS", evidenceType: "flowSession", numericValue: Double(fs.challengeRating)))
        }

        return build(evidence: evidenceList, profile: profile)
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}

// MARK: - Evidence Repository

@MainActor
enum EvidenceRepository {
    static func allEvidence(context: ModelContext) -> [AttentionEvidence] {
        (try? context.fetch(FetchDescriptor<AttentionEvidence>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)]))) ?? []
    }

    static func evidence(forDimension dimension: String, context: ModelContext) -> [AttentionEvidence] {
        let descriptor = FetchDescriptor<AttentionEvidence>(
            predicate: #Predicate { $0.dimension == dimension },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func recordEvidence(
        dimension: String,
        evidenceType: String,
        numericValue: Double? = nil,
        categoricalValue: String? = nil,
        confidence: Double = 0.6,
        sourceID: String? = nil,
        metadata: String = "",
        context: ModelContext
    ) {
        let evidence = AttentionEvidence(
            dimension: dimension,
            evidenceType: evidenceType,
            numericValue: numericValue,
            categoricalValue: categoricalValue,
            confidence: confidence,
            sourceID: sourceID,
            metadata: metadata
        )
        context.insert(evidence)
        try? context.save()
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
        curriculum: ProtocolDay,
        userProfile: RebootUserProfile? = nil
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
            let selected = Self.selectIntervention(profile: profile, userProfile: userProfile, interventions: interventions)
            if let selected {
                realWorldAction = selected.title
                fallback = selected.fallbackActionID.map { id in
                    ContentStore.environmentIntervention(id: id)?.title ?? selected.instructions.first ?? selected.title
                } ?? selected.instructions.first ?? selected.title
                reasons.append("intervention=\(selected.id):\(selected.category)")
            } else {
                realWorldAction = realWorldAction.isEmpty ? "Intervention environnement : éloigne le téléphone de la table." : realWorldAction
            }
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

        // 5. Known absorption contexts but weak work → flow conditions target.
        let hasKnownFlow = profile.flowReadiness.value.contains("KNOWN") || profile.flowReadiness.value == "MEDIUM"
        if hasKnownFlow, profile.stability.value == "LOW" || profile.stability.value == "MEDIUM" {
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

        // 7. Experiment recommendation (one major active experiment at a time).
        let activeExperiments = experiments.filter { $0.status == "BASELINE" || $0.status == "RUNNING" || $0.status == "active" }
        if activeExperiments.isEmpty, profile.environment.value == "WEAK" || profile.reflex.value == "HIGH" {
            let template = ContentStore.experimentTemplates.first { $0.id == 1 }
            realWorldAction = realWorldAction + (template.map { " Expérience suggérée : \($0.title)." } ?? " Expérience suggérée : PHONE OUTSIDE ROOM.")
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

    /// Intervention ladder: pick the next structural change matching primary distractor,
    /// never jumping to extreme restriction, never repeating a completed one.
    static func selectIntervention(
        profile: AttentionProfile,
        userProfile: RebootUserProfile? = nil,
        interventions: [CompletedIntervention]
    ) -> EnvironmentIntervention? {
        let done = Set(interventions.map { $0.interventionID })
        let pool = ContentStore.environmentInterventions

        let distractor = userProfile?.primaryDistractor.lowercased() ?? ""
        let goal = userProfile?.primaryGoal.lowercased() ?? ""

        let preferredCategories: [String]
        if distractor.contains("tiktok") || distractor.contains("reels") || distractor.contains("instagram") || distractor.contains("x") || distractor.contains("social") || distractor.contains("reddit") || distractor.contains("youtube") {
            preferredCategories = ["SOCIAL MEDIA", "PHONE", "HOME SCREEN"]
        } else if distractor.contains("browser") || distractor.contains("tab") || distractor.contains("web") || distractor.contains("internet") {
            preferredCategories = ["BROWSER", "TABS", "WORKSPACE"]
        } else if distractor.contains("notif") || distractor.contains("message") || distractor.contains("whatsapp") || distractor.contains("email") || distractor.contains("work") {
            preferredCategories = ["NOTIFICATIONS", "MESSAGING"]
        } else if goal.contains("read") || goal.contains("study") || goal.contains("concentrat") || goal.contains("deep") {
            preferredCategories = ["WORKSPACE", "LOCATION", "AUDIO", "ROUTINE"]
        } else {
            preferredCategories = ["PHONE", "NOTIFICATIONS", "WORKSPACE"]
        }

        let preferred = pool.filter { preferredCategories.contains($0.category) }
        let candidates = preferred.filter { !done.contains($0.id) }.sorted { $0.difficulty < $1.difficulty }
        let selected = candidates.first
            ?? pool.filter { !done.contains($0.id) }.sorted { $0.difficulty < $1.difficulty }.first
        return selected
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
        case "F":
            p.goalsRaw = ["lire plus longtemps"]
            p.primaryGoal = "LECTURE"
            p.primaryDistractor = "Messages"
            p.capacityBucket = "30–45"
            p.returnDifficulty = 2
            p.readsTenPages = "Oui"
            p.switchingFrequency = 2
            p.existingFlowActivitiesRaw = ["reading"]
            p.phoneLocation = "desk"
            p.notificationsLevel = "many"
            p.openTabsBucket = "5"
            p.usesScreenTimeLimits = "Non"
            p.bestWindow = "morning"
            p.typicalSleep = "7–8"
            p.currentEnergy = "Normal"
            p.caffeine = "Morning only"
        case "G":
            p.goalsRaw = ["mieux travailler"]
            p.primaryGoal = "DEEP WORK"
            p.primaryDistractor = "Work notifications"
            p.capacityBucket = "20–30"
            p.returnDifficulty = 3
            p.readsTenPages = "Parfois"
            p.switchingFrequency = 4
            p.existingFlowActivitiesRaw = ["coding"]
            p.phoneLocation = "desk"
            p.notificationsLevel = "many"
            p.openTabsBucket = "10–20"
            p.usesScreenTimeLimits = "Non"
            p.bestWindow = "afternoon"
            p.typicalSleep = "7–8"
            p.currentEnergy = "Normal"
            p.caffeine = "Morning + afternoon"
        case "H":
            p.goalsRaw = ["retrouver de la concentration"]
            p.primaryGoal = "CONCENTRATION"
            p.primaryDistractor = "YouTube"
            p.capacityBucket = "10–20"
            p.returnDifficulty = 4
            p.readsTenPages = "Non"
            p.switchingFrequency = 4
            p.existingFlowActivitiesRaw = ["music"]
            p.phoneLocation = "pocket"
            p.notificationsLevel = "many"
            p.openTabsBucket = "10"
            p.usesScreenTimeLimits = "Non"
            p.bestWindow = "evening"
            p.typicalSleep = "<5"
            p.currentEnergy = "Low"
            p.caffeine = "Morning + afternoon"
        default:
            break
        }
        return p
    }
}
#endif
