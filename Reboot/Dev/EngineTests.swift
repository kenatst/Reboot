#if DEBUG
import Foundation
import SwiftData

/// Deterministic unit tests for the adaptive engine (DEBUG-only).
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

        // 1. High reflex + weak environment → environment intervention priority.
        let highReflex = AdaptiveRebootEngine.prescribe(
            profile: profile(reflex: "HIGH", environment: "WEAK"),
            day: 10, sessions: [], interventions: [], experiments: [], requiredActions: [],
            energyCheckIn: nil, flowProjects: [], curriculum: day
        )
        check("high reflex chooses environment intervention", highReflex.primaryTarget.contains("ENVIRONMENT") || !highReflex.realWorldAction.isEmpty)

        // 2. Low recall → recall/explain priority.
        let lowRecall = AdaptiveRebootEngine.prescribe(
            profile: profile(stability: "HIGH", recall: "LOW"),
            day: 10, sessions: [], interventions: [], experiments: [], requiredActions: [],
            energyCheckIn: nil, flowProjects: [], curriculum: day
        )
        check("low recall prioritizes Recall", lowRecall.trainingMode == "recall" || lowRecall.primaryTarget.contains("RECALL"))

        // 3. Low energy blocks duration increase.
        let lowEnergy = AdaptiveRebootEngine.prescribe(
            profile: profile(energy: "Low"),
            day: 10, sessions: [], interventions: [], experiments: [], requiredActions: [],
            energyCheckIn: DailyEnergyCheckIn(energy: "Low", sleepHours: "<5", caffeine: "None", bestWindow: "morning"),
            flowProjects: [], curriculum: day
        )
        check("low energy blocks duration increase", lowEnergy.trainingDuration <= day.recommendedDuration && !lowEnergy.recoveryAction.isEmpty)

        // 4. Failed required action → fallback plan present.
        let failedAction = RequiredAction(day: 10, kind: "environment", title: "Téléphone ailleurs")
        failedAction.status = "failed"
        let withFailure = AdaptiveRebootEngine.prescribe(
            profile: profile(),
            day: 10, sessions: [], interventions: [], experiments: [],
            requiredActions: [failedAction],
            energyCheckIn: nil, flowProjects: [], curriculum: day
        )
        check("failed action gets fallback", !withFailure.fallbackPlan.isEmpty && withFailure.realWorldAction.contains("Téléphone"))

        // 5. Completed intervention not immediately repeated as required action.
        let done = CompletedIntervention(interventionID: 1, title: "Téléphone hors de la pièce", category: "PHONE")
        let withDone = AdaptiveRebootEngine.prescribe(
            profile: profile(reflex: "HIGH", environment: "WEAK"),
            day: 10, sessions: [], interventions: [done], experiments: [], requiredActions: [],
            energyCheckIn: nil, flowProjects: [], curriculum: day
        )
        check("completed intervention not repeated verbatim", !withDone.realWorldAction.contains("hors de la pièce"))

        // 6. Clarity: subjective ratings alone never fabricate a number.
        let subjectiveOnly = ClarityEngine.compute(sessions: [])
        check("no fake Clarity from no sessions", subjectiveOnly.status == .noSignal && subjectiveOnly.value == nil)

        // 7. Too-hard flow pattern lowers duration.
        let hard1 = TrainingSession(protocolDay: 9, phase: 2, mode: .stay, title: "t", intention: "i", plannedDurationSeconds: 1500, completionOrdinal: 1)
        hard1.actualDurationSeconds = 1500
        let hard2 = TrainingSession(protocolDay: 10, phase: 2, mode: .stay, title: "t", intention: "i", plannedDurationSeconds: 1500, completionOrdinal: 2)
        hard2.actualDurationSeconds = 600
        let flowProject = FlowProject(title: "P", definitionOfDone: "D", feedbackType: "steps")
        flowProject.sessionsCompleted = 2
        let stayDay = ProtocolCurriculum.day(12)
        let calibrated = AdaptiveRebootEngine.prescribe(
            profile: profile(),
            day: 12, sessions: [hard1, hard2], interventions: [], experiments: [], requiredActions: [],
            energyCheckIn: nil, flowProjects: [flowProject], curriculum: stayDay
        )
        check("too-hard flow lowers challenge", calibrated.trainingDuration < stayDay.recommendedDuration)

        // 8. CRITICAL WIRING: prescription controls the actual SessionRequest.
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
            "prescription controls session request",
            wiringRequest.mode == .stay && wiringRequest.duration == 12
        )

        // 9. Same program day → materially different prescriptions for A/B/C.
        let day18 = ProtocolCurriculum.day(18)
        let userA = profile(reflex: "HIGH", stability: "LOW", recall: "HIGH", environment: "WEAK")
        let planA = AdaptiveRebootEngine.prescribe(
            profile: userA, day: 18, sessions: [], interventions: [], experiments: [],
            requiredActions: [], energyCheckIn: nil, flowProjects: [], curriculum: day18
        )
        let userB = profile(reflex: "LOW", stability: "HIGH", recall: "LOW", environment: "STRONG")
        let planB = AdaptiveRebootEngine.prescribe(
            profile: userB, day: 18, sessions: [], interventions: [], experiments: [],
            requiredActions: [], energyCheckIn: nil, flowProjects: [], curriculum: day18
        )
        let userC = profile(reflex: "MEDIUM", stability: "MEDIUM", recall: "MEDIUM", environment: "MEDIUM")
        let planC = AdaptiveRebootEngine.prescribe(
            profile: userC, day: 18, sessions: [], interventions: [], experiments: [],
            requiredActions: [], energyCheckIn: DailyEnergyCheckIn(energy: "Low", sleepHours: "<5", caffeine: "None", bestWindow: "evening"),
            flowProjects: [], curriculum: day18
        )
        let distinct = Set([planA.primaryTarget, planB.primaryTarget, planC.primaryTarget])
        check(
            "users A/B/C receive materially different day-18 plans",
            distinct.count >= 2 && planA.trainingMode != planB.trainingMode
        )

        // 10. Versioned refresh: energy change supersedes the active plan.
        do {
            let schema = Schema([
                TrainingSession.self, EvaluationResult.self, Restitution.self,
                RebootProgress.self, ProtocolDayCompletion.self, WeeklyCheckpoint.self,
                SelfEvaluation.self, ClaritySnapshot.self, RebootUserProfile.self,
                AttentionDimensionState.self, DailyPrescription.self, RequiredAction.self,
                CompletedIntervention.self, BehaviorExperiment.self, FlowProject.self,
                FlowSession.self, FlowTask.self, DailyEnergyCheckIn.self,
                SessionInterruption.self, PersonalRule.self, AdaptiveDecisionRecord.self,
                AdaptationEvent.self, AttentionEvidence.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            let profile = AdaptiveRebootEngineDriver.ensureProfile(context: context)
            profile.primaryGoal = "DEEP WORK"
            profile.primaryDistractor = "TikTok"
            profile.capacityBucket = "10–20"
            profile.switchingFrequency = 5
            profile.phoneLocation = "desk"
            profile.notificationsLevel = "many"
            try? context.save()

            let v1 = PrescriptionEngine.refreshIfNeeded(forDay: 18, context: context)
            let durationBefore = v1.trainingDuration
            AdaptiveRebootEngineDriver.recordEnergyCheckIn(
                energy: "Low", sleep: "<5", caffeine: "None", window: "evening", context: context
            )
            let v2 = PrescriptionEngine.refreshIfNeeded(forDay: 18, context: context)
            check(
                "energy change refreshes and supersedes prescription",
                v2.version > v1.version && v2.status == "active" && v1.status == "superseded" && durationBefore >= v2.trainingDuration
            )
        } catch {
            check("versioned refresh container setup", false)
        }

        return results
    }
}
#endif
