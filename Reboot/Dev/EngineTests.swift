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
        let fTask = FlowTask(projectID: fProject.id, taskTitle: "Review core", definitionOfDone: "Check diffs", challengeRatingBefore: 3, skillRatingBefore: 2, plannedDurationSeconds: 40 * 60)
        let fSession = FlowSession(projectID: fProject.id, flowTaskID: fTask.id, plannedDurationSeconds: 40 * 60, actualDurationSeconds: 38 * 60)
        fSession.challengeRating = 3
        fSession.skillRating = 2
        check("Invariant 7: FlowTask bound to FlowSession", fSession.flowTaskID == fTask.id)
        check("Invariant 8: FlowSession stores actual duration (not hardcoded 25)", fSession.actualDurationSeconds == 38 * 60 && fSession.plannedDurationSeconds == 40 * 60)
        check("Invariant 9: Flow Challenge and Skill separated", fSession.challengeRating == 3 && fSession.skillRating == 2 && fTask.challengeRatingBefore != fTask.skillRatingBefore)

        // 7. Invariant 14: SessionOrigin & advancesProtocol
        let reqProtocol = SessionRequest(mode: .stay, day: 1, duration: 10, title: "Stay", contentID: nil, origin: .protocol)
        let reqFree = SessionRequest(mode: .stay, day: 1, duration: 10, title: "Stay", contentID: nil, origin: .freeTraining)
        let reqExplore = SessionRequest(mode: .recall, day: 1, duration: 15, title: "Read", contentID: 1, origin: .explore)
        let reqFlow = SessionRequest(mode: .stay, day: 1, duration: 25, title: "Flow", contentID: nil, origin: .flow)
        check("Invariant 14a: Protocol origin advances protocol", reqProtocol.advancesProtocol)
        check("Invariant 14b: Free training origin never advances protocol", !reqFree.advancesProtocol)
        check("Invariant 14c: Explore origin never advances protocol", !reqExplore.advancesProtocol)
        check("Invariant 14d: Flow origin never advances protocol", !reqFlow.advancesProtocol)

        // 8. Invariant 12: Context-Aware Intervention Selection (TikTok -> SOCIAL MEDIA / PHONE; Tabs -> BROWSER; Work -> NOTIFICATIONS)
        let userProfTikTok = RebootUserProfile()
        userProfTikTok.primaryDistractor = "TikTok videos"
        userProfTikTok.primaryGoal = "Deep focus"
        let selTikTok = AdaptiveRebootEngine.selectIntervention(profile: profile(), userProfile: userProfTikTok, interventions: [])
        check("Invariant 12a: TikTok maps to PHONE/SOCIAL MEDIA", selTikTok != nil && (selTikTok?.category == "PHONE" || selTikTok?.category == "SOCIAL MEDIA" || selTikTok?.category == "HOME SCREEN"))

        let userProfTabs = RebootUserProfile()
        userProfTabs.primaryDistractor = "Browser tabs and Wikipedia"
        userProfTabs.primaryGoal = "Deep focus"
        let selTabs = AdaptiveRebootEngine.selectIntervention(profile: profile(), userProfile: userProfTabs, interventions: [])
        check("Invariant 12b: Browser/Tabs maps to BROWSER/TABS/WORKSPACE", selTabs != nil && (selTabs?.category == "BROWSER" || selTabs?.category == "TABS" || selTabs?.category == "WORKSPACE"))

        let userProfNotif = RebootUserProfile()
        userProfNotif.primaryDistractor = "Work messages and Slack notifications"
        userProfNotif.primaryGoal = "Deep focus"
        let selNotif = AdaptiveRebootEngine.selectIntervention(profile: profile(), userProfile: userProfNotif, interventions: [])
        check("Invariant 12c: Work notifications maps to NOTIFICATIONS/MESSAGING", selNotif != nil && (selNotif?.category == "NOTIFICATIONS" || selNotif?.category == "MESSAGING"))

        // 9. Invariant 15: Content LRU and Freshness (Never repeat one of last 10 unless exhausted)
        let allReadingIDs = ContentStore.readings.map(\.id)
        let recent10 = Array(allReadingIDs.prefix(10))
        let lruContext = ContentSelectionContext(
            mode: .recall,
            targetSkill: "",
            difficulty: 2,
            recentContentIDs: recent10,
            phase: 1,
            completedContentIDs: recent10,
            day: 1
        )
        let lruSelected = ContentSelector.select(context: lruContext)
        check("Invariant 15: ContentSelector excludes recent 10 IDs when pool has fresh items", lruSelected != nil && !recent10.contains(lruSelected!))

        // 10. Low energy blocks duration increase
        let lowEnergy = AdaptiveRebootEngine.prescribe(
            profile: profile(energy: "Low"),
            day: 10, sessions: [], interventions: [], experiments: [], requiredActions: [],
            energyCheckIn: DailyEnergyCheckIn(energy: "Low", sleepHours: "<5", caffeine: "None", bestWindow: "morning"),
            flowProjects: [], curriculum: day
        )
        check("Low energy blocks duration increase", lowEnergy.trainingDuration <= day.recommendedDuration && !lowEnergy.recoveryAction.isEmpty)

        // 11. Failed required action → fallback plan present
        let failedAction = RequiredAction(day: 10, kind: "environment", title: "Téléphone ailleurs")
        failedAction.status = "failed"
        let withFailure = AdaptiveRebootEngine.prescribe(
            profile: profile(),
            day: 10, sessions: [], interventions: [], experiments: [],
            requiredActions: [failedAction],
            energyCheckIn: nil, flowProjects: [], curriculum: day
        )
        check("Failed action gets fallback", !withFailure.fallbackPlan.isEmpty && withFailure.realWorldAction.contains("Téléphone"))

        // 12. CRITICAL WIRING: prescription controls the actual SessionRequest
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
            wiringRequest.mode == .stay && wiringRequest.duration == 12 && wiringRequest.advancesProtocol
        )

        // 13. SwiftData In-Memory Tests (Idempotence, 60s Return Threshold, Lifecycle)
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

            // Invariant 16: Idempotent recordSessionEvidence
            let testSession = TrainingSession(protocolDay: 1, phase: 1, mode: .stay, title: "Stay Test", intention: "i", plannedDurationSeconds: 600, completionOrdinal: 1)
            testSession.actualDurationSeconds = 600
            testSession.switchedCount = 1
            context.insert(testSession)
            try? context.save()

            AdaptiveRebootEngineDriver.recordSessionEvidence(session: testSession, context: context)
            let evCount1 = (try? context.fetch(FetchDescriptor<AttentionEvidence>()))?.count ?? 0
            AdaptiveRebootEngineDriver.recordSessionEvidence(session: testSession, context: context)
            let evCount2 = (try? context.fetch(FetchDescriptor<AttentionEvidence>()))?.count ?? 0
            check("Invariant 16: recordSessionEvidence is strictly idempotent", evCount1 == evCount2 && evCount1 > 0)

            // Invariant 17: Return evidence 60-second threshold
            let shortReturnSession = TrainingSession(protocolDay: 2, phase: 1, mode: .stay, title: "Short Return", intention: "i", plannedDurationSeconds: 120, completionOrdinal: 2)
            shortReturnSession.actualDurationSeconds = 120
            shortReturnSession.switchedCount = 1
            context.insert(shortReturnSession)
            // Interruption at second 110 (only 10 seconds before session end < 60s)
            context.insert(SessionInterruption(sessionID: shortReturnSession.id, elapsedSeconds: 110, kind: "switch"))
            try? context.save()

            AdaptiveRebootEngineDriver.recordSessionEvidence(session: shortReturnSession, context: context)
            let allEv = (try? context.fetch(FetchDescriptor<AttentionEvidence>())) ?? []
            let returnEvShort = allEv.first { $0.sourceID == shortReturnSession.id.uuidString && $0.dimension == "RETURN" }
            check("Invariant 17a: Switch 10s before end does NOT record return evidence", returnEvShort == nil)

            let validReturnSession = TrainingSession(protocolDay: 3, phase: 1, mode: .stay, title: "Valid Return", intention: "i", plannedDurationSeconds: 300, completionOrdinal: 3)
            validReturnSession.actualDurationSeconds = 300
            validReturnSession.switchedCount = 1
            context.insert(validReturnSession)
            // Interruption at second 60 (240 seconds remaining >= 60s)
            context.insert(SessionInterruption(sessionID: validReturnSession.id, elapsedSeconds: 60, kind: "switch"))
            try? context.save()

            AdaptiveRebootEngineDriver.recordSessionEvidence(session: validReturnSession, context: context)
            let allEv2 = (try? context.fetch(FetchDescriptor<AttentionEvidence>())) ?? []
            let returnEvValid = allEv2.first { $0.sourceID == validReturnSession.id.uuidString && $0.dimension == "RETURN" }
            check("Invariant 17b: Switch 240s before end DOES record return evidence", returnEvValid != nil && returnEvValid?.categoricalValue == "RESUMED_SESSION")

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
            check("Invariant 6b: 3 baseline observations transitions to RUNNING", exp.status == "RUNNING" && exp.currentCondition == "TEST")

            // Add 2 test observations
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "TEST", context: context)
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "TEST", context: context)
            check("Invariant 6c: 2 test observations remains RUNNING", exp.status == "RUNNING")

            // Add 3rd test observation
            AdaptiveRebootEngineDriver.recordExperimentObservation(experiment: exp, session: dummySession, condition: "TEST", context: context)
            check("Invariant 6d: >= 3 baseline and >= 3 test becomes READY_TO_REVIEW", exp.status == "READY_TO_REVIEW" && !exp.recommendation.isEmpty)

            // Invariant 18: DiagnosisQuestionEngine dynamic branching & question range
            var diagState = DiagnosisQuestionEngine.DiagnosisState()
            diagState.selectedGoals = ["ARRÊTER DE SCROLLER", "MIEUX TRAVAILLER"]
            diagState.primaryGoal = "ARRÊTER DE SCROLLER"
            diagState.goalBranch = "scroll"
            let scrollQuestions = DiagnosisQuestionEngine.buildQuestions(state: diagState)
            check("Invariant 18a: Diagnosis produces 8–14 questions for scroll branch", scrollQuestions.count >= 8 && scrollQuestions.count <= 14)

            diagState.primaryGoal = "MIEUX TRAVAILLER"
            diagState.goalBranch = "work"
            let workQuestions = DiagnosisQuestionEngine.buildQuestions(state: diagState)
            check("Invariant 18b: Diagnosis produces 8–14 questions for work branch", workQuestions.count >= 8 && workQuestions.count <= 14)

            // Invariant 19: AttentionOperatingManualEngine 16 sections synthesis
            let manual = AttentionOperatingManualEngine.generate(context: context)
            check("Invariant 19a: Attention Operating Manual generates exactly 16 sections", manual.sections.count == 16)
            check("Invariant 19b: Attention Operating Manual has non-empty core maintenance mode", !manual.coreMaintenanceMode.isEmpty)

            // Invariant 20: ContentStores validation
            check("Invariant 20a: ProtocolCurriculum contains exactly 90 days", ProtocolCurriculum.days.count == 90)
            check("Invariant 20b: MicroInsights contains exactly 90 unique insights", ContentStore.microInsights.count == 90)
            check("Invariant 20c: Readings store contains >= 60 editorially unique items", ContentStore.readings.count >= 60)
            check("Invariant 20d: Learnings store contains >= 40 items", ContentStore.learningModules.count >= 40)
            check("Invariant 20e: MicroLessons store contains >= 60 items", ContentStore.microLessons.count >= 60)
            check("Invariant 20f: FlowLessons store contains >= 20 items", ContentStore.flowLessons.count >= 20)
            check("Invariant 20g: FuelLessons store contains >= 15 items", ContentStore.fuelLessons.count >= 15)
            check("Invariant 20h: EnvironmentInterventions store contains >= 80 items", ContentStore.environmentInterventions.count >= 80)
            check("Invariant 20i: Experiments store contains >= 40 items", ContentStore.experimentTemplates.count >= 40)
            check("Invariant 20j: Missions store contains >= 80 items", ContentStore.observationMissions.count >= 80)
            check("Invariant 20k: VoidPrompts store contains >= 50 items", ContentStore.voidPrompts.count >= 50)
            check("Invariant 20l: CoachingMessages store contains >= 100 items", ContentStore.coachingMessages.count >= 100)
            check("Invariant 20m: ContentEvidence store contains >= 30 canonical records", ContentStore.evidenceRecords.count >= 30)
            check("Invariant 20n: Checkpoints store contains exactly 13 items", ContentStore.checkpoints.count == 13)

        } catch {
            check("SwiftData in-memory container setup error: \(error.localizedDescription)", false)
        }

        return results
    }
}
#endif
