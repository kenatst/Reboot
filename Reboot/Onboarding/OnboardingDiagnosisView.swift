import SwiftUI
import SwiftData

/// REBOOT V3 — Adaptive Branching Diagnosis View
/// Dynamically queries 8–14 questions based on primary goal branch and produces
/// the genuine starting map without synthetic scores.
struct OnboardingDiagnosisView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var state = DiagnosisQuestionEngine.DiagnosisState()
    @State private var currentIndex = 0
    @State private var finished = false

    private var questions: [DiagnosisQuestionEngine.Question] {
        DiagnosisQuestionEngine.buildQuestions(state: state)
    }

    private var currentQuestion: DiagnosisQuestionEngine.Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if finished {
                startingMap
            } else if let q = currentQuestion {
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        renderQuestion(q)
                            .padding(.horizontal, RBSpacing.screen)
                            .padding(.top, 24)
                    }
                    footer
                }
            }
        }
        .onAppear {
            #if DEBUG
            if UITestDriver.diagnosisAutoAdvance {
                runAutoDiagnosis()
            }
            #endif
        }
    }

    private var header: some View {
        HStack {
            RBStatusChip(text: "REBOOT / CALIBRATION", color: .signalCyan, pulse: true)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.ash)
            }
            Text(String(format: "%02d / %02d", min(currentIndex + 1, questions.count), questions.count))
                .font(.metadata(size: 10))
                .tracking(1.6)
                .foregroundStyle(.ash)
                .padding(.leading, 14)
        }
        .padding(.horizontal, RBSpacing.screen)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func renderQuestion(_ q: DiagnosisQuestionEngine.Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(q.title)
                .font(.heroBlack(size: 26))
                .foregroundStyle(.bone)
                .lineSpacing(-2)
            if !q.subtitle.isEmpty {
                Text(q.subtitle)
                    .font(.body(size: 13))
                    .foregroundStyle(.ash)
            }

            switch q.kind {
            case .single(let options):
                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = getSingleSelection(q.id) == option
                        selectableRow(option, selected: isSelected) {
                            setSingleSelection(q.id, value: option)
                        }
                    }
                }

            case .multi(let options):
                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let selectedList = getMultiSelection(q.id)
                        let isSelected = selectedList.contains(option)
                        selectableRow(option, selected: isSelected) {
                            toggleMultiSelection(q.id, value: option)
                        }
                    }
                }

            case .text(let placeholder, let presets):
                VStack(alignment: .leading, spacing: 12) {
                    TextField(placeholder, text: Binding(
                        get: { getTextSelection(q.id) },
                        set: { setTextSelection(q.id, value: $0) }
                    ), axis: .vertical)
                    .font(.body(size: 16))
                    .foregroundStyle(.bone)
                    .lineLimit(2...4)
                    .padding(16)
                    .background(Color.deepCarbon)
                    .overlay(Rectangle().stroke(Color.line, lineWidth: 1))

                    if !presets.isEmpty {
                        Text("OU CHOISIS UNE CIBLE TYPIQUE :")
                            .font(.metadata(size: 9))
                            .tracking(1.4)
                            .foregroundStyle(.ash)
                            .padding(.top, 6)

                        ForEach(presets, id: \.self) { preset in
                            Button {
                                setTextSelection(q.id, value: preset)
                            } label: {
                                HStack {
                                    Text(preset)
                                        .font(.body(size: 13))
                                        .foregroundStyle(getTextSelection(q.id) == preset ? .ink : .bone)
                                    Spacer()
                                }
                                .padding(12)
                                .background(getTextSelection(q.id) == preset ? Color.bonePlate : Color.deepCarbon)
                                .clipShape(RBChamferedShape(cut: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

            case .slider(let low, let high):
                VStack(spacing: 12) {
                    Slider(value: Binding(
                        get: { Double(getSliderSelection(q.id)) },
                        set: { setSliderSelection(q.id, value: Int($0.rounded())) }
                    ), in: 1...5, step: 1)
                    .tint(.signalCyan)
                    HStack {
                        Text(low).font(.metadata(size: 9)).foregroundStyle(.ash)
                        Spacer()
                        Text("\(getSliderSelection(q.id))").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundStyle(.signalCyan)
                        Spacer()
                        Text(high).font(.metadata(size: 9)).foregroundStyle(.ash)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.bottom, 20)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                Button {
                    withAnimation { currentIndex -= 1 }
                } label: {
                    Text("RETOUR")
                        .font(.metadata(size: 10))
                        .tracking(1.4)
                        .foregroundStyle(.ash)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
            }
            Button {
                withAnimation { advance() }
            } label: {
                HStack {
                    Text(currentIndex >= questions.count - 1 ? "VOIR MA CARTE" : "SUIVANT")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.rbSystem)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.4)
        }
        .padding(.horizontal, RBSpacing.screen)
        .padding(.bottom, 18)
    }

    private var canAdvance: Bool {
        guard let q = currentQuestion else { return false }
        switch q.kind {
        case .single:
            return !getSingleSelection(q.id).isEmpty
        case .multi:
            return !getMultiSelection(q.id).isEmpty
        case .text:
            return !getTextSelection(q.id).trimmingCharacters(in: .whitespaces).isEmpty
        case .slider:
            return true
        }
    }

    private func advance() {
        if currentIndex >= questions.count - 1 {
            save()
            withAnimation(.easeOut(duration: 0.3)) {
                finished = true
            }
        } else {
            currentIndex += 1
        }
    }

    // State Accessors
    private func getSingleSelection(_ id: String) -> String {
        switch id {
        case "primaryGoal": return state.primaryGoal
        case "scroll_app": return state.primaryDistractor
        case "scroll_moments": return state.triggerContext
        case "work_type": return state.workType
        case "work_breaker": return state.workBreaker
        case "work_capacity": return state.capacityBucket
        case "study_purpose": return state.studyPurpose
        case "study_bottleneck": return state.studyBottleneck
        case "study_explain": return state.canExplainCourse
        case "study_capacity": return state.capacityBucket
        case "reading_target": return state.readingTarget
        case "reading_mode": return state.readingFailureMode
        case "reading_ten_pages": return state.readsTenPages
        case "focus_breaker": return state.primaryDistractor
        case "focus_capacity": return state.capacityBucket
        case "env_phone": return state.phoneLocation
        case "env_notifs": return state.notifications
        case "env_tabs": return state.tabs
        case "energy_window": return state.bestWindow
        case "energy_sleep": return state.sleep
        default: return ""
        }
    }

    private func setSingleSelection(_ id: String, value: String) {
        switch id {
        case "primaryGoal":
            state.primaryGoal = value
            state.goalBranch = DiagnosisQuestionEngine.determineBranch(primaryGoal: value)
        case "scroll_app": state.primaryDistractor = value
        case "scroll_moments": state.triggerContext = value
        case "work_type": state.workType = value
        case "work_breaker":
            state.workBreaker = value
            state.primaryDistractor = value
        case "work_capacity": state.capacityBucket = value
        case "study_purpose": state.studyPurpose = value
        case "study_bottleneck": state.studyBottleneck = value
        case "study_explain": state.canExplainCourse = value
        case "study_capacity": state.capacityBucket = value
        case "reading_target": state.readingTarget = value
        case "reading_mode": state.readingFailureMode = value
        case "reading_ten_pages": state.readsTenPages = value
        case "focus_breaker": state.primaryDistractor = value
        case "focus_capacity": state.capacityBucket = value
        case "env_phone": state.phoneLocation = value
        case "env_notifs": state.notifications = value
        case "env_tabs": state.tabs = value
        case "energy_window": state.bestWindow = value
        case "energy_sleep": state.sleep = value
        default: break
        }
    }

    private func getMultiSelection(_ id: String) -> [String] {
        switch id {
        case "goals": return state.selectedGoals
        case "flow_activities": return state.flowActivities
        case "flow_why": return state.flowDifferences
        default: return []
        }
    }

    private func toggleMultiSelection(_ id: String, value: String) {
        switch id {
        case "goals":
            if state.selectedGoals.contains(value) {
                state.selectedGoals.removeAll { $0 == value }
            } else {
                state.selectedGoals.append(value)
            }
            if state.primaryGoal.isEmpty || !state.selectedGoals.contains(state.primaryGoal) {
                state.primaryGoal = state.selectedGoals.first ?? ""
                state.goalBranch = DiagnosisQuestionEngine.determineBranch(primaryGoal: state.primaryGoal)
            }
        case "flow_activities":
            if state.flowActivities.contains(value) {
                state.flowActivities.removeAll { $0 == value }
            } else {
                state.flowActivities.append(value)
            }
        case "flow_why":
            if state.flowDifferences.contains(value) {
                state.flowDifferences.removeAll { $0 == value }
            } else {
                state.flowDifferences.append(value)
            }
        default: break
        }
    }

    private func getTextSelection(_ id: String) -> String {
        switch id {
        case "scroll_outcome", "work_outcome": return state.desiredOutcome
        default: return ""
        }
    }

    private func setTextSelection(_ id: String, value: String) {
        switch id {
        case "scroll_outcome", "work_outcome": state.desiredOutcome = value
        default: break
        }
    }

    private func getSliderSelection(_ id: String) -> Int {
        switch id {
        case "return_diff": return state.returnDifficulty
        default: return 3
        }
    }

    private func setSliderSelection(_ id: String, value: Int) {
        switch id {
        case "return_diff": state.returnDifficulty = value
        default: break
        }
    }

    private func save() {
        let profile = AdaptiveRebootEngineDriver.ensureProfile(context: modelContext)
        profile.goalsRaw = state.selectedGoals
        profile.primaryGoal = state.primaryGoal.isEmpty ? (state.selectedGoals.first ?? "RETROUVER DE LA CONCENTRATION") : state.primaryGoal
        profile.goalBranch = DiagnosisQuestionEngine.determineBranch(primaryGoal: profile.primaryGoal)
        profile.primaryDistractor = !state.primaryDistractor.isEmpty ? state.primaryDistractor : (state.workBreaker.isEmpty ? "Téléphone" : state.workBreaker)
        profile.distractorTriggerContext = state.triggerContext
        profile.desiredOutcome = state.desiredOutcome
        profile.workType = state.workType
        profile.workBreaker = state.workBreaker
        profile.studyPurpose = state.studyPurpose
        profile.studyBottleneck = state.studyBottleneck
        profile.canExplainCourse = state.canExplainCourse
        profile.readingTarget = state.readingTarget
        profile.readingFailureMode = state.readingFailureMode
        profile.capacityBucket = state.capacityBucket
        profile.returnDifficulty = state.returnDifficulty
        profile.readsTenPages = state.readsTenPages
        profile.switchingFrequency = state.switchingFrequency
        profile.existingFlowActivitiesRaw = state.flowActivities
        profile.flowDifferenceRaw = state.flowDifferences
        profile.knownAbsorptionContext = state.flowActivities.first ?? "Non renseigné"
        profile.flowConditionHypothesesRaw = state.flowDifferences
        profile.phoneLocation = state.phoneLocation
        profile.notificationsLevel = state.notifications
        profile.openTabsBucket = state.tabs
        profile.bestWindow = state.bestWindow
        profile.typicalSleep = state.sleep
        profile.currentEnergy = state.energy
        profile.caffeine = state.caffeine
        try? modelContext.save()

        AdaptiveRebootEngineDriver.recordEnergyCheckIn(
            energy: state.energy, sleep: state.sleep, caffeine: state.caffeine, window: state.bestWindow, context: modelContext
        )
    }

    // Starting Map Output
    private var startingMap: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RBSystemLabel(text: "REBOOT / CARTE INITIALE", color: .signalCyan)
                    .padding(.top, 34)

                Text("TA CARTE\nDE DÉPART.")
                    .font(.heroBlack(size: 38))
                    .tracking(-0.4)
                    .foregroundStyle(.bone)
                    .padding(.top, 16)

                Text("Pas de faux score. REBOOT calibre ton attention réelle à partir d'aujourd'hui.")
                    .font(.body(size: 13))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    summaryRow("OBJECTIF PRINCIPAL", state.primaryGoal.isEmpty ? (state.selectedGoals.first ?? "CONCENTRATION") : state.primaryGoal)
                    summaryRow("BRISURE PRINCIPALE", !state.primaryDistractor.isEmpty ? state.primaryDistractor : (!state.workBreaker.isEmpty ? state.workBreaker : "TÉLÉPHONE"))
                    summaryRow("FENÊTRE ACTUELLE", "\(state.capacityBucket) MIN")
                    summaryRow("OBSTACLE LIKELY", determineBottleneck())
                    summaryRow("ABSORPTION CONNUE", state.flowActivities.first ?? "EN COURS")
                    summaryRow("ENVIRONNEMENT", "\(state.phoneLocation.uppercased()) · \(state.notifications.uppercased())")
                    summaryRow("STATUT", "CALIBRATION (JOURS 01–07)")
                }
                .padding(18)
                .background(Color.graphiteSurface)
                .clipShape(RBChamferedShape(cut: 16))
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 6) {
                    Text("CE QUI SE PASSE MAINTENANT")
                        .font(.metadata(size: 10))
                        .tracking(1.8)
                        .foregroundStyle(.signalCyan)
                    Text("Les 7 premiers jours ne te demandent pas d'être parfait. Ils mesurent ta stabilité de base, ta friction d'environnement et ton seuil de décrochage.")
                        .font(.body(size: 13))
                        .foregroundStyle(.softBone)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Color.deepCarbon)
                .clipShape(RBChamferedShape(cut: 12))
                .padding(.top, 20)

                Button {
                    AdaptiveRebootEngineDriver.generatePrescription(forDay: 1, context: modelContext)
                    dismiss()
                } label: {
                    HStack {
                        Text("DÉMARRER LE PROTOCOLE")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.rbSystem)
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, RBSpacing.screen)
        }
    }

    private func determineBottleneck() -> String {
        if !state.studyBottleneck.isEmpty {
            return state.studyBottleneck.uppercased()
        }
        if state.goalBranch == "scroll" {
            return "RÉFLEXE DE VÉRIFICATION"
        }
        if state.goalBranch == "work" {
            return state.workBreaker.isEmpty ? "DISPERSION NUMÉRIQUE" : state.workBreaker.uppercased()
        }
        if state.goalBranch == "reading" {
            return state.readingFailureMode.isEmpty ? "VAGABONDAGE" : state.readingFailureMode.uppercased()
        }
        return "MAINTIEN ATTENTIONNEL"
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.metadata(size: 10))
                .tracking(1.6)
                .foregroundStyle(.ash)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.bone)
                .multilineTextAlignment(.trailing)
        }
    }

    private func selectableRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body(size: 15))
                    .foregroundStyle(selected ? .ink : .bone)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.ink)
                }
            }
            .padding(14)
            .background(selected ? Color.bonePlate : Color.deepCarbon)
            .clipShape(RBChamferedShape(cut: 10))
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
    private func runAutoDiagnosis() {
        state.selectedGoals = ["ARRÊTER DE SCROLLER", "MIEUX TRAVAILLER"]
        state.primaryGoal = "ARRÊTER DE SCROLLER"
        state.primaryDistractor = "TikTok"
        state.triggerContext = "Lit avant de dormir"
        state.desiredOutcome = "Instagram ≤ 30 min / jour"
        state.capacityBucket = "10–20"
        state.flowActivities = ["Code & Programmation"]
        state.flowDifferences = ["Feedback instantané"]
        state.phoneLocation = "Sur le bureau"
        state.notifications = "Beaucoup de bannières"
        state.bestWindow = "Matin tôt"
        state.sleep = "7–8 heures"
        save()
        finished = true
    }
    #endif
}
