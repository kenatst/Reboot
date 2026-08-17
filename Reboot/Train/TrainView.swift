import SwiftUI
import SwiftData

/// TRAIN — choose your signal. Editorial discipline system, curated not generated.
struct TrainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [RebootProgress]
    @Query private var prescriptions: [DailyPrescription]
    @State private var activeRequest: SessionRequest?
    @State private var showingProgram = false
    @State private var exploreMode: SessionMode?
    @State private var showFlowLab = false
    @State private var showExperiments = false

    private var progress: RebootProgress? {
        progressList.first
    }

    private var dayNumber: Int {
        ProtocolEngine.currentDay(progress: progress)
    }

    private var plan: ProtocolDay {
        ProtocolCurriculum.day(dayNumber)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 14)

                    Text("CHOISIS\nTON SIGNAL.")
                        .font(.heroBlack(size: 40))
                        .tracking(-0.4)
                        .foregroundStyle(.bone)
                        .padding(.top, 26)

                    assignedToday
                        .padding(.top, 26)

                    Text("LES DISCIPLINES")
                        .font(.metadata(size: 10))
                        .tracking(2)
                        .foregroundStyle(.ash)
                        .padding(.top, 34)

                    disciplineGrid
                        .padding(.top, 14)

                    exploreSection
                        .padding(.top, 34)
                        .padding(.bottom, 110)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .fullScreenCover(item: $activeRequest) { request in
            SessionFlowView(request: request)
        }
        .sheet(isPresented: $showingProgram) {
            NavigationStack {
                ProgramView()
            }
        }
        .sheet(item: $exploreMode) { mode in
            ExploreLibraryView(mode: mode)
        }
        .sheet(isPresented: $showFlowLab) {
            FlowLabView()
        }
        .sheet(isPresented: $showExperiments) {
            ExperimentsView()
        }
    }

    private var activePrescriptionForToday: DailyPrescription? {
        prescriptions.activePrescription(forDay: dayNumber)
    }

    private var header: some View {
        HStack {
            RBSystemLabel(text: "REBOOT / TRAIN", color: .ash)
            Spacer()
            RBDayCounter(day: dayNumber)
        }
    }

    private var assignedToday: some View {
        let prescription = activePrescriptionForToday
        let assignedMode = prescription.flatMap { SessionMode(rawValue: $0.trainingMode) } ?? plan.mode
        let assignedDuration = prescription?.trainingDuration ?? plan.recommendedDuration
        let assignedTarget = prescription?.primaryTarget ?? plan.skill

        return RBSignalPlate(cut: 24, accent: Color.phaseAccent(plan.phase), fill: .deepCarbon) {
            Button {
                if let p = prescription {
                    activeRequest = SessionRequestFactory.prescription(prescription: p, curriculum: plan, context: modelContext)
                } else {
                    let p = AdaptiveRebootEngineDriver.generatePrescription(forDay: dayNumber, context: modelContext)
                    activeRequest = SessionRequestFactory.prescription(prescription: p, curriculum: plan, context: modelContext)
                }
            } label: {
                HStack(spacing: 16) {
                    RBModeGlyph(kind: modeGlyph(assignedMode), size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ASSIGNÉ AUJOURD'HUI")
                            .font(.metadata(size: 9))
                            .tracking(2)
                            .foregroundStyle(.ash)
                        Text("DAY \(String(format: "%03d", dayNumber)) — \(assignedMode.frenchLabel)")
                            .font(.system(size: 17, weight: .bold, design: .default))
                            .foregroundStyle(.bone)
                        Text("\(assignedDuration) MIN · \(assignedTarget)")
                            .font(.body(size: 12))
                            .foregroundStyle(.softBone)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.phaseAccent(plan.phase))
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var disciplineGrid: some View {
        VStack(spacing: 14) {
            disciplineModule(.stay, index: 1, flip: false)
            disciplineModule(.recall, index: 2, flip: true)
            disciplineModule(.explain, index: 3, flip: false)
            disciplineModule(.nothing, index: 4, flip: true)
            disciplineModule(.observe, index: 5, flip: false)
        }
    }

    private func disciplineModule(_ mode: SessionMode, index: Int, flip: Bool) -> some View {
        let kind = modeGlyph(mode)
        let accent = kind.accent
        return HStack(spacing: 0) {
            if flip {
                contentFor(mode, accent: accent)
                RBModeNode(kind: kind, index: index)
                    .frame(width: 92)
            } else {
                RBModeNode(kind: kind, index: index)
                    .frame(width: 92)
                contentFor(mode, accent: accent)
            }
        }
        .background(Color.deepCarbon)
        .clipShape(RBChamferedShape(cut: flip ? 22 : 6))
        .overlay(
            RBChamferedShape(cut: flip ? 22 : 6)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        )
    }

    private func contentFor(_ mode: SessionMode, accent: Color) -> some View {
        Button {
            activeRequest = SessionRequestFactory.discipline(mode, day: dayNumber, context: modelContext)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(mode.label)
                    .font(.metadata(size: 10))
                    .tracking(2)
                    .foregroundStyle(accent)
                Text(mode.frenchLabel)
                    .font(.system(size: 18, weight: .heavy, design: .default))
                    .foregroundStyle(.bone)
                Text(mode.tagline)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "EXPLORE")
            Text("Explore des exercices hors protocole. Ces sessions ne font pas avancer les 90 jours.")
                .font(.body(size: 13))
                .foregroundStyle(.ash)
                .lineSpacing(3)
                .padding(.top, 12)

            HStack(spacing: 10) {
                exploreButton("LIRE", .recall)
                exploreButton("APPRENDRE", .explain)
                exploreButton("OBSERVER", .observe)
            }
            .padding(.top, 14)
            HStack(spacing: 10) {
                systemButton("FLOW LAB", "waveform.path.ecg") {
                    showFlowLab = true
                }
                systemButton("EXPÉRIENCES", "flask") {
                    showExperiments = true
                }
            }
            .padding(.top, 10)
        }
    }

    private func exploreButton(_ label: String, _ mode: SessionMode) -> some View {
        Button {
            exploreMode = mode
        } label: {
            VStack(spacing: 6) {
                RBModeGlyph(kind: modeGlyph(mode), size: 22)
                Text(label)
                    .font(.metadata(size: 9))
                    .tracking(1.4)
                    .foregroundStyle(.softBone)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 10))
        }
        .buttonStyle(.plain)
    }

    private func systemButton(_ label: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(label)
                    .font(.metadata(size: 10))
                    .tracking(1.4)
            }
            .foregroundStyle(.bone)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 10))
        }
        .buttonStyle(.plain)
    }

    private func modeGlyph(_ mode: SessionMode) -> RBModeGlyphKind {
        switch mode {
        case .stay: return .stay
        case .recall: return .recall
        case .explain: return .explain
        case .nothing: return .nothing
        case .observe: return .observe
        }
    }
}

/// Browsable content libraries for optional practice (does not advance the protocol).
struct ExploreLibraryView: View {
    let mode: SessionMode
    @Environment(\.dismiss) private var dismiss
    @State private var selection: ExploreSelection?

    struct ExploreSelection: Identifiable {
        let id: Int
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        RBSystemLabel(text: "REBOOT / EXPLORE", color: .ash)
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

                    Text(mode.frenchLabel)
                        .font(.heroBlack(size: 36))
                        .foregroundStyle(.bone)
                        .padding(.top, 18)

                    rows
                        .padding(.top, 22)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .fullScreenCover(item: $selection) { selection in
            SessionFlowView(request: exploreRequest(id: selection.id))
        }
    }

    @ViewBuilder
    private var rows: some View {
        switch mode {
        case .recall:
            ForEach(ContentStore.readings) { reading in
                editorialRow(
                    title: reading.title,
                    meta: "\(reading.category) · \(reading.length.label) · \(reading.readingMinutes) MIN",
                    accent: .softBone
                ) { selection = ExploreSelection(id: reading.id) }
            }
        case .explain:
            ForEach(ContentStore.learningModules) { module in
                editorialRow(
                    title: module.title,
                    meta: "\(module.topic) · \(module.readingMinutes) MIN",
                    accent: .acid
                ) { selection = ExploreSelection(id: module.id) }
            }
        default:
            ForEach(ContentStore.observationMissions) { mission in
                editorialRow(
                    title: mission.title,
                    meta: "\(mission.category) · MISSION \(String(format: "%03d", mission.id))",
                    accent: .signalRed
                ) { selection = ExploreSelection(id: mission.id) }
            }
        }
    }

    private func editorialRow(title: String, meta: String, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Rectangle()
                    .fill(accent)
                    .frame(width: 3, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundStyle(.bone)
                        .multilineTextAlignment(.leading)
                    Text(meta)
                        .font(.metadata(size: 9))
                        .tracking(1.2)
                        .foregroundStyle(.ash)
                        .textCase(.uppercase)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func exploreRequest(id: Int) -> SessionRequest {
        SessionRequest(
            mode: mode,
            day: ProtocolEngine.currentDay(progress: nil),
            duration: 15,
            title: titleFor(id: id),
            contentID: id,
            origin: .explore
        )
    }

    private func titleFor(id: Int) -> String {
        switch mode {
        case .recall: return ContentStore.reading(id: id)?.title ?? "LECTURE"
        case .explain: return ContentStore.learning(id: id)?.title ?? "LEÇON"
        default: return ContentStore.mission(id: id)?.title ?? "MISSION"
        }
    }
}
