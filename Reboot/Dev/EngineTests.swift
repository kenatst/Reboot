#if DEBUG
import Foundation

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

        return results
    }
}
#endif
