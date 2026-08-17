import SwiftUI
import SwiftData

/// FLOW LAB — build the conditions for deep engagement, never promise flow.
struct FlowLabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var projects: [FlowProject]

    @State private var showBuilder = false
    @State private var activeProject: FlowProject?
    @State private var selectedLesson: FlowLesson?

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        RBSystemLabel(text: "REBOOT / FLOW LAB", color: .signalCyan)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.ash)
                        }
                    }
                    .padding(.top, 18)

                    Text("LES CONDITIONS\nDE LA PROFONDEUR.")
                        .font(.heroBlack(size: 36))
                        .tracking(-0.4)
                        .foregroundStyle(.bone)
                        .padding(.top, 18)

                    Button {
                        showBuilder = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NOUVEAU PROJET FLOW")
                                    .font(.metadata(size: 10))
                                    .tracking(2)
                                    .foregroundStyle(.signalCyan)
                                Text("Un objectif clair, une fin définie, un feedback.")
                                    .font(.body(size: 13))
                                    .foregroundStyle(.softBone)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundStyle(.signalCyan)
                        }
                        .padding(18)
                        .background(Color.deepCarbon)
                        .clipShape(RBChamferedShape(cut: 16))
                        .overlay(RBChamferedShape(cut: 16).stroke(Color.signalCyan.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)

                    if !projects.isEmpty {
                        Text("PROJETS")
                            .font(.metadata(size: 10))
                            .tracking(2)
                            .foregroundStyle(.ash)
                            .padding(.top, 30)
                        VStack(spacing: 10) {
                            ForEach(projects) { project in
                                Button {
                                    activeProject = project
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(project.title)
                                                .font(.system(size: 16, weight: .bold, design: .default))
                                                .foregroundStyle(.bone)
                                            Text("FINI : \(project.definitionOfDone)")
                                                .font(.body(size: 12))
                                                .foregroundStyle(.ash)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Text("\(project.sessionsCompleted) SESSIONS")
                                            .font(.metadata(size: 9))
                                            .foregroundStyle(.signalCyan)
                                    }
                                    .padding(14)
                                    .background(Color.graphiteSurface)
                                    .clipShape(RBChamferedShape(cut: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 12)
                    }

                    Text("PRINCIPES")
                        .font(.metadata(size: 10))
                        .tracking(2)
                        .foregroundStyle(.ash)
                        .padding(.top, 30)
                    VStack(spacing: 10) {
                        ForEach(ContentStore.flowLessons) { lesson in
                            Button {
                                selectedLesson = lesson
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Rectangle()
                                        .fill(Color.signalCyan)
                                        .frame(width: 3, height: 34)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(lesson.title)
                                            .font(.system(size: 15, weight: .bold, design: .default))
                                            .foregroundStyle(.bone)
                                        Text(lesson.text)
                                            .font(.body(size: 12))
                                            .foregroundStyle(.ash)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.deepCarbon)
                                .clipShape(RBChamferedShape(cut: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .sheet(isPresented: $showBuilder) {
            FlowBuilderView()
        }
        .fullScreenCover(item: $activeProject) { project in
            FlowSessionView(project: project)
        }
        .sheet(item: $selectedLesson) { lesson in
            ZStack {
                Color.void.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(lesson.title)
                            .font(.heroBlack(size: 30))
                            .foregroundStyle(.bone)
                            .padding(.top, 26)
                        Text(lesson.text)
                            .font(.reading(size: 18))
                            .foregroundStyle(.softBone)
                            .lineSpacing(7)
                            .padding(.top, 20)
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, RBSpacing.screen)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            #if DEBUG
            if UITestDriver.autoTour || UITestDriver.flowBuilderAuto {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showBuilder = true
                }
            }
            if UITestDriver.autoTour {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    let project: FlowProject
                    if let first = projects.first {
                        project = first
                    } else {
                        project = FlowProject(title: "Préparer la présentation client", definitionOfDone: "Slides 1–5 finalisées", feedbackType: "slides")
                        modelContext.insert(project)
                        try? modelContext.save()
                    }
                    activeProject = project
                }
            }
            #endif
        }
    }
}

/// Step 1 of the Flow builder: define the project.
struct FlowBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var done = ""
    @State private var feedback = "étapes"
    @State private var goalClarity = 2
    @State private var challenge = 2
    @State private var duration = 25
    @State private var contract = "hors de la pièce"

    private let feedbackOptions = ["pages", "questions", "slides", "code tests", "paragraphes", "problèmes résolus", "autre"]

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBStatusChip(text: "FLOW BUILDER", color: .signalCyan, pulse: false)
                        .padding(.top, 30)
                    Text("QU'EST-CE QUE\nTU VAS FAIRE ?")
                        .font(.heroBlack(size: 36))
                        .foregroundStyle(.bone)
                        .padding(.top, 20)

                    field("ACTIVITÉ", placeholder: "Préparer présentation client…", text: $title)
                        .padding(.top, 24)
                    field("CE QUE « TERMINÉ » SIGNIFIE", placeholder: "Slides 1–5 finalisées…", text: $done)
                        .padding(.top, 18)

                    Text("COMMENT VERRAIS-TU QUE TU PROGRESSES ?")
                        .font(.metadata(size: 11))
                        .tracking(1.4)
                        .foregroundStyle(.ash)
                        .padding(.top, 24)
                    HStack(spacing: 8) {
                        ForEach(feedbackOptions, id: \.self) { option in
                            Button {
                                feedback = option
                            } label: {
                                Text(option)
                                    .font(.metadata(size: 9))
                                    .foregroundStyle(feedback == option ? .ink : .bone)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(feedback == option ? Color.bonePlate : Color.deepCarbon)
                                    .clipShape(RBChamferedShape(cut: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 10)

                    Button {
                        guard !title.isEmpty, !done.isEmpty else { return }
                        let project = FlowProject(title: title, definitionOfDone: done, feedbackType: feedback, goalClarity: goalClarity)
                        project.defaultSessionLength = duration
                        project.defaultDistractionContract = contract
                        project.skillEstimate = challenge
                        modelContext.insert(project)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        HStack {
                            Text("CRÉER LE PROJET")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbSystem)
                    .padding(.top, 30)
                    .disabled(title.isEmpty || done.isEmpty)
                    .opacity(title.isEmpty || done.isEmpty ? 0.4 : 1)

                    Text("LE DÉFI TE SEMBLE…")
                        .font(.metadata(size: 10))
                        .tracking(1.6)
                        .foregroundStyle(.ash)
                        .padding(.top, 22)
                    HStack(spacing: 8) {
                        ForEach(["TROP FACILE", "JUSTE", "TROP DUR"], id: \.self) { option in
                            let value = ["TROP FACILE", "JUSTE", "TROP DUR"].firstIndex(of: option)! + 1
                            Button {
                                challenge = value
                            } label: {
                                Text(option)
                                    .font(.metadata(size: 9))
                                    .foregroundStyle(challenge == value ? .ink : .bone)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(challenge == value ? Color.bonePlate : Color.deepCarbon)
                                    .clipShape(RBChamferedShape(cut: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)

                    Text("DURÉE DE LA FENÊTRE")
                        .font(.metadata(size: 10))
                        .tracking(1.6)
                        .foregroundStyle(.ash)
                        .padding(.top, 18)
                    HStack(spacing: 8) {
                        ForEach([15, 25, 40, 60], id: \.self) { d in
                            Button {
                                duration = d
                            } label: {
                                Text("\(d)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(duration == d ? .ink : .bone)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(duration == d ? Color.bonePlate : Color.deepCarbon)
                                    .clipShape(RBChamferedShape(cut: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)

                    Text("TÉLÉPHONE PENDANT LA SESSION")
                        .font(.metadata(size: 10))
                        .tracking(1.6)
                        .foregroundStyle(.ash)
                        .padding(.top, 18)
                    HStack(spacing: 8) {
                        ForEach(["hors de la pièce", "face cachée", "mode focus", "autorisé"], id: \.self) { option in
                            Button {
                                contract = option
                            } label: {
                                Text(option)
                                    .font(.metadata(size: 9))
                                    .foregroundStyle(contract == option ? .ink : .bone)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(contract == option ? Color.bonePlate : Color.deepCarbon)
                                    .clipShape(RBChamferedShape(cut: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.metadata(size: 10))
                .tracking(1.6)
                .foregroundStyle(.ash)
            TextField(placeholder, text: text, axis: .vertical)
                .font(.body(size: 16))
                .foregroundStyle(.bone)
                .lineLimit(2...4)
                .padding(14)
                .background(Color.deepCarbon)
                .overlay(Rectangle().stroke(Color.line, lineWidth: 1))
        }
    }
}

/// A Flow session: timer with the project contract, then 4 post questions.
struct FlowSessionView: View {
    let project: FlowProject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var remaining: Int
    @State private var switches = 0
    @State private var finished = false
    @State private var knewNextStep = 3
    @State private var challenge = 2
    @State private var lostTrack = "Parfois"
    @State private var wantedContinue = "Oui"

    init(project: FlowProject) {
        self.project = project
        self._remaining = State(initialValue: max(10, project.defaultSessionLength) * 60)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if !finished {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.ash)
                        }
                    }
                    .padding(.horizontal, 20)
                    RBSystemLabel(text: "FLOW / \(project.title.uppercased())", color: .signalCyan)
                        .padding(.top, 14)
                    Text("TERMINÉ : \(project.definitionOfDone)")
                        .font(.body(size: 13))
                        .foregroundStyle(.softBone)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    Spacer()
                    RBTimerDisplay(seconds: remaining, size: 70)
                    Text("FEEDBACK : \(project.feedbackType.uppercased())")
                        .font(.metadata(size: 9))
                        .tracking(1.4)
                        .foregroundStyle(.signalCyan)
                        .padding(.top, 10)
                    Text("CONTRAT : TÉLÉPHONE \(project.defaultDistractionContract.isEmpty ? "HORS DE LA PIÈCE" : project.defaultDistractionContract.uppercased())")
                        .font(.metadata(size: 9))
                        .tracking(1.4)
                        .foregroundStyle(.ash)
                        .padding(.top, 4)
                    Spacer()
                    HStack(spacing: 14) {
                        Button {
                            switches += 1
                        } label: {
                            Text("I SWITCHED")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.signalRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .overlay(Rectangle().stroke(Color.signalRed.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        Button {
                            finish()
                        } label: {
                            Text("TERMINER")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.bonePlate)
                                .clipShape(RBChamferedShape(cut: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    Task {
                        while remaining > 0 && !finished {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            remaining -= 1
                        }
                        if remaining <= 0 { finish() }
                    }
                }
            } else {
                postSession
            }
        }
        .onAppear {
            #if DEBUG
            if UITestDriver.flowAutoFinish {
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    finish()
                }
            }
            #endif
        }
        .onChange(of: finished) { _, isFinished in
            #if DEBUG
            if isFinished, UITestDriver.autoTour || UITestDriver.flowAutoFinish {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    saveSession()
                    dismiss()
                }
            }
            #endif
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
    }

    private var postSession: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RBStatusChip(text: "FLOW / POST-SESSION", color: .signalCyan, pulse: false)
                    .padding(.top, 34)
                Text("QUATRE QUESTIONS.")
                    .font(.heroBlack(size: 34))
                    .foregroundStyle(.bone)
                    .padding(.top, 20)

                rating("SAVAIS-TU QUOI FAIRE ENSUITE ?", value: $knewNextStep, low: "PAS DU TOUT", high: "TRÈS CLAIR")
                challengeRow
                singleChoice("AS-TU PERDU LA NOTION DU TEMPS ?", options: ["Non", "Un peu", "Oui"], selection: $lostTrack)
                singleChoice("AVAIS-TU ENVIE DE CONTINUER ?", options: ["Non", "Neutre", "Oui"], selection: $wantedContinue)

                Button {
                    saveSession()
                    dismiss()
                } label: {
                    HStack {
                        Text("ENREGISTRER")
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
                .buttonStyle(.rbSystem)
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, RBSpacing.screen)
        }
    }

    private var challengeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LE DÉFI ÉTAIT…")
                .font(.metadata(size: 11))
                .tracking(1.6)
                .foregroundStyle(.ash)
            HStack(spacing: 8) {
                ForEach(["TROP FACILE", "JUSTE", "TROP DUR"], id: \.self) { option in
                    let value = ["TROP FACILE", "JUSTE", "TROP DUR"].firstIndex(of: option)! + 1
                    Button {
                        challenge = value
                    } label: {
                        Text(option)
                            .font(.metadata(size: 9))
                            .foregroundStyle(challenge == value ? .ink : .bone)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(challenge == value ? Color.bonePlate : Color.deepCarbon)
                            .clipShape(RBChamferedShape(cut: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 26)
    }

    private func rating(_ title: String, value: Binding<Int>, low: String, high: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.metadata(size: 11))
                .tracking(1.6)
                .foregroundStyle(.ash)
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0.rounded()) }
            ), in: 1...5, step: 1)
            .tint(.signalCyan)
            HStack {
                Text(low).font(.metadata(size: 8)).foregroundStyle(.ash)
                Spacer()
                Text(high).font(.metadata(size: 8)).foregroundStyle(.ash)
            }
        }
        .padding(.top, 26)
    }

    private func singleChoice(_ title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.metadata(size: 11))
                .tracking(1.6)
                .foregroundStyle(.ash)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(.metadata(size: 11))
                            .foregroundStyle(selection.wrappedValue == option ? .ink : .bone)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selection.wrappedValue == option ? Color.bonePlate : Color.deepCarbon)
                            .clipShape(RBChamferedShape(cut: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 26)
    }

    private func saveSession() {
        let flowSession = FlowSession(projectID: project.id, durationSeconds: 25 * 60)
        flowSession.challengeRating = challenge
        flowSession.knewNextStep = knewNextStep
        flowSession.lostTrackOfTime = lostTrack
        flowSession.wantedToContinue = wantedContinue
        flowSession.switchCount = switches
        flowSession.completed = true
        modelContext.insert(flowSession)
        project.sessionsCompleted += 1
        try? modelContext.save()
    }
}
