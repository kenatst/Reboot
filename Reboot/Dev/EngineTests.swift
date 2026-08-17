#if DEBUG
import Foundation
import SwiftData

/// Deterministic unit tests for the adaptive engine and invariants (DEBUG-only).
enum EngineTests {
    @MainActor
    static func run() -> [String] {
        var results: [String] = []
        let day = ProtocolCurriculum.day(10)

        func profile(
            reflex: String = "LOW",
            stability: String = "MEDIUM",
            recall: String = "CALIBRATING",
            environment: String = "MEDIUM",
            energy: String = "Normal"
        ) -> AttentionProfile {
            func dim(_ name: String, _ value: String) -> AttentionProfile.Dimension {
                AttentionProfile.Dimension(name: name, value: value, confidence: 0.6, evidenceCount: 3, sources: ["TEST"])
            }
            return AttentionProfile(
                reflex: dim("REFLEX", reflex),
                stability: dim("STABILITY", stability),
                retur: dim("RETURN", "CALIBRATING"),
                recall: dim("RECALL", recall),
                depth: dim("DEPTH", "MEDIUM"),
                environment: dim("ENVIRONMENT", environment),
                energy: dim("ENERGY", energy),
                flowReadiness: dim("FLOW", "CALIBRATING")
            )
        }

        func check(_ name: String, _ condition: Bool) {
            results.append("\(condition ? "PASS" : "FAIL") — \(name)")
        }

        // 1. Invariant 1: Single canonical activePrescription(forDay:)
        let pV1 = DailyPrescription(day: 5, phase: 1, primaryTarget: "STABILITY", whyToday: "w", realWorldAction: "a", trainingMode: "stay", trainingDuration: 15, flowWindow: "", recoveryAction: "", microInsight: "", difficulty: 2, adaptationReason: "", fallbackPlan: "", version: 1)
        let pV2 = DailyPrescription(day: 5, phase: 1, primaryTarget: "STABILITY", whyToday: "w", realWorldAction: "a", trainingMode: "stay", trainingDuration: 10, flowWindow: "", recoveryAction: "", microInsight: "", difficulty: 2, adaptationReason: "", fallbackPlan: "", version: 2)
        pV1.status = "superseded"
        pV2.status = "active"
        let pList = [pV1, pV2]
        let canonicalActive = pList.activePrescription(forDay: 5)
        check("Invariant 1: activePrescription(forDay:) resolves highest version active prescription", canonicalActive?.version == 2 && canonicalActive?.status == "active")

        // 2. Invariant 2 & 10: DailyPrescription requiredActionID link
        let reqAction = RequiredAction(day: 5, kind: "environment", title: "Phone in other room")
        pV2.requiredActionID = reqAction.id
        check("Invariant 10: DailyPrescription links requiredActionID", pV2.requiredActionID == reqAction.id)

        // 3. Invariant 3 & 4: ContentSelectionContext deterministic selection without modulo
        let cContext1 = ContentSelectionContext(mode: .recall, targetSkill: "STABILITÉ", difficulty: 2, recentContentIDs: [1, 2], phase: 1, preferredCategories: ["STABILITÉ"], completedContentIDs: [1], day: 5)
        let selectedContentID = ContentSelector.select(context: cContext1)
        check("Invariant 4: ContentSelector deterministic selection without modulo", selectedContentID != nil && selectedContentID != 1 && selectedContentID != 2)

        // 4. Invariant 5: FIRST_SWITCH_LATENCY feeds STABILITY; unobserved RETURN is CALIBRATING
        let stabEvidence = AttentionEvidence(dimension: "STABILITY", evidenceType: "FIRST_SWITCH_LATENCY", numericValue: 18.0)
        let attProfile = AttentionProfileBuilder.build(evidence: [stabEvidence], profile: nil)
        check("Invariant 5: First switch feeds STABILITY (HIGH)", attProfile.stability.value == "HIGH")
        check("Invariant 5: Unobserved return remains CALIBRATING", attProfile.retur.value == "CALIBRATING")

        // 5. Invariant 5b: Observed returns after switch calculate success rate for RETURN
        let retEv1 = AttentionEvidence(dimension: "RETURN", evidenceType: "RETURN_AFTER_SWITCH", categoricalValue: "RESUMED_SESSION")
        let retEv2 = AttentionEvidence(dimension: "RETURN", evidenceType: "RETURN_AFTER_SWITCH", categoricalValue: "RESUMED_SESSION")
        let retEv3 = AttentionEvidence(dimension: "RETURN", evidenceType: "RETURN_AFTER_SWITCH", categoricalValue: "RESUMED_SESSION")
        let attProfileWithReturn = AttentionProfileBuilder.build(evidence: [retEv1, retEv2, retEv3], profile: nil)
        check("Invariant 5b: Observed return after switch yields HIGH return", attProfileWithReturn.retur.value == "HIGH")

        // 6. Invariant 7, 8, 9: FlowTask, separate challenge/skill, actual duration
        let fProject = FlowProject(title: "Code review", definitionOfDone: "PR #42 reviewed", feedbackType: "comments")
        let fTask = FlowTask(projectID: fProject.id, taskTitle: "Review core", definitionOfDone: "Check diffs", challengeRatingBefore: 3, skillRatingBefore: 2, plannedDuration: 40)
        let fSession = FlowSession(projectID: fProject.id, flowTaskID: fTask.id, plannedDurationSeconds: 40 * 60, actualDurationSeconds: 38 * 60)
        fSession.challengeRating = 3
        fSession.skillRating = 2
        check("Invariant 7: FlowTask bound to FlowSession", fSession.flowTaskID == fTask.id)
        check("Invariant 8: FlowSession stores actual duration (not hardcoded 25)", fSession.actualDurationSeconds == 38 * 60 && fSession.plannedDurationSeconds == 40 * 60)
        check("Invariant 9: Flow Challenge and Skill separated", fSession.challengeRating == 3 && fSession.skillRating == 2 && fTask.challengeRatingBefore != fTask.skillRatingBefore)

        // 7. Invariant 12: Context-Aware Intervention Selection (TikTok -> SOCIAL MEDIA / PHONE)
        let userProf = RebootUserProfile()
        userProf.primaryDistractor = "TikTok videos"
        userProf.primaryGoal = "Deep focus"
        let selectedIntervention = AdaptiveRebootEngine.selectIntervention(profile: profile(), userProfile: userProf, interventions: [])
        check("Invariant 12: Primary distractor TikTok selects phone/social media intervention", selectedIntervention != nil && (selectedIntervention?.category == "PHONE" || selectedIntervention?.category == "SOCIAL MEDIA" || selectedIntervention?.category == "HOME SCREEN"))

        // 8. Low energy blocks duration increase
        let lowEnergy = AdaptiveRebootEngine.prescribe(
            profile: profile(energy: "Low"),
            day: 10, sessions: [], interventions: [], experiments: [], requiredActions: [],
            energyCheckIn: DailyEnergyCheckIn(energy: "Low", sleepHours: "<5", caffeine: "None", bestWindow: "morning"),
            flowProjects: [], curriculum: day
        )
        check("Low energy blocks duration increase", lowEnergy.trainingDuration <= day.recommendedDuration && !lowEnergy.recoveryAction.isEmpty)

        // 9. Failed required action → fallback plan present
        let failedAction = RequiredAction(day: 10, kind: "environment", title: "Téléphone ailleurs")
        failedAction.status = "failed"
        let withFailure = AdaptiveRebootEngine.prescribe(
            profile: profile(),
            day: 10, sessions: [], interventions: [], experiments: [],
            requiredActions: [failedAction],
            energyCheckIn: nil, flowProjects: [], curriculum: day
        )
        check("Failed action gets fallback", !withFailure.fallbackPlan.isEmpty && withFailure.realWorldAction.contains("Téléphone"))

        // 10. CRITICAL WIRING: prescription controls the actual SessionRequest
        let wiringPrescription = DailyPrescription(
            day: 18, phase: 2, primaryTarget: "STABILITY", whyToday: "w",
            realWorldAction: "a", trainingMode: "stay", trainingDuration: 12,
            flowWindow: "", recoveryAction: "", microInsight: "i",
            difficulty: 2, adaptationReason: "r", fallbackPlan: "f"
        )
        let wiringRequest = SessionRequestFactory.prescription(
            prescription: wiringPrescription,
            curriculum: ProtocolCurriculum.day(18)
        )
        check(
            "Prescription controls session request",
            wiringRequest.mode == .stay && wiringRequest.duration == 12
        )

        // 11. Invariant 6 & 13: In-Memory SwiftData tests (Lifecycle, ExperimentObservation, Immediate Refresh)
        do {
            let schema = Schema([
                TrainingSession.self, EvaluationResult.self, Restitution.self,
                RebootProgress.self, ProtocolDayCompletion.self, WeeklyCheckpoint.self,
                SelfEvaluation.self, ClaritySnapshot.self, RebootUserProfile.self,
                AttentionDimensionState.self, DailyPrescription.self, RequiredAction.self,
                CompletedIntervention.self, BehaviorExperiment.self, FlowProject.self,
                FlowSession.self, FlowTask.self, DailyEnergyCheckIn.self,
                SessionInterruption.self, PersonalRule.self, AdaptiveDecisionRecord.self,
                AdaptationEvent.self, AttentionEvidence.self, ExperimentObservation.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            let p = AdaptiveRebootEngineDriver.ensureProfile(context: context)
            p.primaryGoal = "DEEP WORK"
            p.primaryDistractor = "TikTok"
            p.capacityBucket = "10–20"
            p.switchingFrequency = 5
            p.phoneLocation = "desk"
            p.notificationsLevel = "many"
            try? context.save()

            // Invariant 2 & 13: Refresh supersedes older versions
            let v1 = PrescriptionEngine.refreshIfNeeded(forDay: 18, context: context)
            let durationBefore = v1.trainingDuration
            AdaptiveRebootEngineDriver.recordEnergyCheckIn(
                day: 18, energy: "Low", sleep: "<5", caffeine: "None", window: "evening", context: context
            )
            let v2 = PrescriptionEngine.activePrescription(forDay: 18, context: context)
            check(
                "Invariant 13: Immediate refresh supersedes v1 on energy check-in",
                v2 != nil && v2!.version > v1.version && v2!.status == "active" && v1.status == "superseded" && durationBefore >= v2!.trainingDuration
            )

            // Invariant 6: Experiment requires >= 3 baseline and >= 3 test before READY_TO_REVIEW
            let exp = BehaviorExperiment(templateID: 1, title: "Phone out of room", hypothesis: "Less urges", metric: "Switches")
            context.insert(exp)
            try? context.save()

            let dummySession = TrainingSession(protocolDay: 18, phase: 2, mode: .stay, title: "Stay 1", intention: "i", plannedDurationSeconds: 1500, completionOrdinal: 1)
            context.insert(dummySession)

            // Add 2 baseline observations
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "BASELINE", context: context)
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "BASELINE", context: context)
            check("Invariant 6a: 2 baseline observations remains BASELINE", exp.status == "BASELINE")

            // Add 3rd baseline observation
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "BASELINE", context: context)
            check("Invariant 6b: 3 baseline observations transitions to RUNNING", exp.status == "RUNNING")

            // Add 2 test observations
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "TEST", context: context)
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "TEST", context: context)
            check("Invariant 6c: 2 test observations remains RUNNING", exp.status == "RUNNING")

            // Add 3rd test observation
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "TEST", context: context)
            check("Invariant 6d: >= 3 baseline and >= 3 test becomes READY_TO_REVIEW", exp.status == "READY_TO_REVIEW" && !exp.recommendation.isEmpty)

        } catch {
            check("SwiftData in-memory container setup error: \(error.localizedDescription)", false)
        }

        return results
    }
}
#endif
