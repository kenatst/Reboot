import SwiftUI
import SwiftData
import UserNotifications

extension Notification.Name {
    static let rebootShowOnboarding = Notification.Name("reboot.showOnboarding")
    static let rebootPreferencesChanged = Notification.Name("reboot.preferencesChanged")
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var haptics = PreferencesStore.shared.hapticsEnabled
    @State private var sound = PreferencesStore.shared.sessionSoundEnabled
    @State private var reminder = PreferencesStore.shared.reminderEnabled
    @State private var reminderHour = PreferencesStore.shared.reminderHour
    @State private var appearance = PreferencesStore.shared.appearance
    @State private var showRestartConfirm = false
    @State private var showResetOnboardingConfirm = false
    @State private var showDeleteConfirm = false
    @State private var exportURL: URL?
    @State private var exportError = false

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBSystemLabel(text: "REBOOT / SETTINGS", color: .ash)
                        .padding(.top, 14)

                    Text("PARAMÈTRES.")
                        .font(.heroBlack(size: 36))
                        .tracking(-0.4)
                        .foregroundStyle(.bone)
                        .padding(.top, 16)

                    toggleRow(
                        title: "HAPTICS",
                        subtitle: "Impacts sur les interruptions et les transitions",
                        value: $haptics
                    ) { PreferencesStore.shared.hapticsEnabled = $0 }

                    toggleRow(
                        title: "SESSION SOUND",
                        subtitle: "Confirmation sonore au verrouillage",
                        value: $sound
                    ) { PreferencesStore.shared.sessionSoundEnabled = $0 }

                    toggleRow(
                        title: "PROTOCOL REMINDER",
                        subtitle: "Rappel quotidien (notification locale)",
                        value: $reminder
                    ) { enabled in
                        PreferencesStore.shared.reminderEnabled = enabled
                        Task {
                            await ReminderScheduler.scheduleIfNeeded(enabled: enabled, hour: reminderHour)
                        }
                    }

                    if reminder {
                        HStack {
                            Text("HEURE DU RAPPEL")
                                .font(.metadata(size: 11))
                                .tracking(1.6)
                                .foregroundStyle(.ash)
                            Spacer()
                            Picker("", selection: $reminderHour) {
                                ForEach(6...22, id: \.self) { hour in
                                    Text(String(format: "%02d:00", hour))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.signalCyan)
                        }
                        .padding(.vertical, 13)
                        .onChange(of: reminderHour) { _, newValue in
                            PreferencesStore.shared.reminderHour = newValue
                            Task {
                                await ReminderScheduler.scheduleIfNeeded(enabled: true, hour: newValue)
                            }
                        }
                    }

                    HStack {
                        Text("APPEARANCE")
                            .font(.metadata(size: 11))
                            .tracking(1.6)
                            .foregroundStyle(.ash)
                        Spacer()
                        Picker("", selection: $appearance) {
                            Text("SYSTÈME").tag("system")
                            Text("VOID").tag("dark")
                            Text("BONE").tag("light")
                        }
                        .pickerStyle(.menu)
                        .tint(.signalCyan)
                    }
                    .padding(.vertical, 13)
                    .onChange(of: appearance) { _, newValue in
                        PreferencesStore.shared.appearance = newValue
                        NotificationCenter.default.post(name: .rebootPreferencesChanged, object: nil)
                    }

                    divider

                    actionRow(title: "EXPORT LOCAL DATA", subtitle: "Toutes tes sessions en JSON") {
                        exportData()
                    }
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            HStack {
                                Text("PARTAGER L'EXPORT")
                                    .font(.metadata(size: 11))
                                    .tracking(1.6)
                                    .foregroundStyle(.signalCyan)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    divider

                    actionRow(title: "RESTART REBOOT", subtitle: "Remet le protocole au jour 001, supprime les sessions") {
                        showRestartConfirm = true
                    }

                    actionRow(title: "RESET ONBOARDING", subtitle: "Revivre les cinq chapitres") {
                        showResetOnboardingConfirm = true
                    }

                    actionRow(title: "DELETE LOCAL DATA", subtitle: "Efface tout, définitivement", destructive: true) {
                        showDeleteConfirm = true
                    }

                    divider

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ABOUT REBOOT")
                            .font(.metadata(size: 11))
                            .tracking(2)
                            .foregroundStyle(.ash)
                        Text("REBOOT — 90 DAYS TO REBOOT YOUR BRAIN.\nREPRENDS TON ATTENTION.\n\nLe protocole avance quand tu t'entraînes, pas quand le calendrier avance. Aucune donnée n'est inventée : tout ce qui est affiché vient de tes sessions.")
                            .font(.body(size: 14))
                            .foregroundStyle(.softBone)
                            .lineSpacing(4)
                        Text("VERSION 1.0")
                            .font(.metadata(size: 10))
                            .tracking(1.4)
                            .foregroundStyle(.ash)
                            .padding(.top, 4)
                        #if DEBUG
                        DevMenuView()
                            .padding(.top, 10)
                        #endif
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.bone)
                }
            }
        }
        .confirmationDialog("RESTART REBOOT", isPresented: $showRestartConfirm, titleVisibility: .visible) {
            Button("REMETTRE AU JOUR 001", role: .destructive) {
                restartReboot()
            }
            Button("ANNULER", role: .cancel) {}
        } message: {
            Text("Le protocole revient au jour 001 et toutes les sessions sont supprimées. Cette action ne peut pas être annulée.")
        }
        .confirmationDialog("RESET ONBOARDING", isPresented: $showResetOnboardingConfirm, titleVisibility: .visible) {
            Button("REVOIR L'ONBOARDING") {
                resetOnboarding()
            }
            Button("ANNULER", role: .cancel) {}
        } message: {
            Text("Les cinq chapitres seront rejoués au prochain lancement.")
        }
        .confirmationDialog("DELETE LOCAL DATA", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("TOUT EFFACER", role: .destructive) {
                deleteAllData()
            }
            Button("ANNULER", role: .cancel) {}
        } message: {
            Text("Sessions, évaluations, protocole et préférences seront supprimés. Rien n'est récupérable.")
        }
        .alert("EXPORT ÉCHOUÉ", isPresented: $exportError) {
            Button("OK", role: .cancel) {}
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.line)
            .frame(height: 1)
            .padding(.vertical, 14)
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        value: Binding<Bool>,
        commit: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.metadata(size: 11))
                    .tracking(1.6)
                    .foregroundStyle(.softBone)
                Text(subtitle)
                    .font(.body(size: 12))
                    .foregroundStyle(.ash)
            }
        }
        .tint(.signalCyan)
        .padding(.vertical, 11)
        .onChange(of: value.wrappedValue) { _, newValue in
            commit(newValue)
            NotificationCenter.default.post(name: .rebootPreferencesChanged, object: nil)
        }
    }

    private func actionRow(title: String, subtitle: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.metadata(size: 11))
                        .tracking(1.6)
                        .foregroundStyle(destructive ? .signalRed : .softBone)
                    Text(subtitle)
                        .font(.body(size: 12))
                        .foregroundStyle(.ash)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.ash.opacity(0.6))
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func restartReboot() {
        wipeData(keepPreferences: true)
        NotificationCenter.default.post(name: .rebootPreferencesChanged, object: nil)
    }

    private func resetOnboarding() {
        PreferencesStore.shared.onboardingCompleted = false
        NotificationCenter.default.post(name: .rebootShowOnboarding, object: nil)
    }

    private func deleteAllData() {
        wipeData(keepPreferences: false)
        PreferencesStore.shared.onboardingCompleted = false
        NotificationCenter.default.post(name: .rebootShowOnboarding, object: nil)
    }

    private func wipeData(keepPreferences: Bool) {
        let context = modelContext
        let types: [any PersistentModel.Type] = [
            TrainingSession.self,
            EvaluationResult.self,
            Restitution.self,
            RebootProgress.self,
            ProtocolDayCompletion.self,
            WeeklyCheckpoint.self,
            SelfEvaluation.self,
            ClaritySnapshot.self,
            RebootUserProfile.self,
            AttentionDimensionState.self,
            DailyPrescription.self,
            RequiredAction.self,
            CompletedIntervention.self,
            BehaviorExperiment.self,
            FlowProject.self,
            FlowSession.self,
            FlowTask.self,
            DailyEnergyCheckIn.self,
            SessionInterruption.self,
            PersonalRule.self,
            AdaptiveDecisionRecord.self,
            AdaptationEvent.self,
            AttentionEvidence.self,
            ExperimentObservation.self
        ]
        for type in types {
            do {
                try context.delete(model: type)
            } catch {
                // Continue clearing what can be cleared.
            }
        }
        try? context.save()
        context.insert(RebootProgress())
        try? context.save()
    }

    private func exportData() {
        let allSessions = (try? modelContext.fetch(FetchDescriptor<TrainingSession>())) ?? []
        let payload = allSessions.map { session -> [String: Any] in
            [
                "date": session.date.timeIntervalSince1970,
                "protocolDay": session.protocolDay,
                "mode": session.modeRaw,
                "durationSeconds": session.actualDurationSeconds,
                "task": session.task,
                "switches": session.switchedCount,
                "response": session.userResponse,
                "calm": session.calm ?? NSNull(),
                "energy": session.energy ?? NSNull(),
                "evaluation": session.evaluation.map { evaluation -> [String: Any] in
                    [
                        "overallScore": evaluation.overallScore,
                        "dimensions": evaluation.dimensions.map { ["name": $0.name, "score": $0.score, "reason": $0.reason] },
                        "strength": evaluation.strength,
                        "mainGap": evaluation.mainGap,
                        "correction": evaluation.correction,
                        "nextChallenge": evaluation.nextChallenge,
                        "confidence": evaluation.confidence,
                        "insufficientEvidence": evaluation.insufficientEvidence,
                        "followUpQuestion": evaluation.followUpQuestion ?? NSNull()
                    ]
                } ?? NSNull()
            ]
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("REBOOT-export-\(Int(Date.now.timeIntervalSince1970)).json")
            try data.write(to: url)
            exportURL = url
        } catch {
            exportError = true
        }
    }
}

enum ReminderScheduler {
    static func scheduleIfNeeded(enabled: Bool, hour: Int) async {
        let center = UNUserNotificationCenter.current()
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: ["reboot.protocolReminder"])
            return
        }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        center.removePendingNotificationRequests(withIdentifiers: ["reboot.protocolReminder"])
        let content = UNMutableNotificationContent()
        content.title = "REBOOT"
        content.body = "Ta session t'attend. Le jour avance quand tu t'entraînes."
        content.sound = .default
        var date = DateComponents()
        date.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: "reboot.protocolReminder", content: content, trigger: trigger))
    }
}
