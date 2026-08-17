import SwiftUI
import SwiftData

/// TODAY — the daily protocol as a destination, not a document.
struct TodayView: View {
    @Query private var progressList: [RebootProgress]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @State private var activeRequest: SessionRequest?
    @State private var showingProgram = false

    private var progress: RebootProgress? {
        progressList.first
    }

    private var dayNumber: Int {
        ProtocolEngine.currentDay(progress: progress)
    }

    private var plan: ProtocolDay {
        ProtocolCurriculum.day(dayNumber)
    }

    private var completedSessions: Int {
        progress?.completedSessions ?? 0
    }

    private var clarity: ClarityEngine.Result {
        ClarityEngine.compute(sessions: sessions)
    }

    private var microInsightText: String {
        ContentStore.microInsight(day: dayNumber)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            RBRadialField(color: accent, opacity: 0.045, diameter: 420)
                .position(x: UIScreen.main.bounds.width * 0.78, y: 140)
            phaseNoiseDecoration

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    systemHeader
                        .padding(.top, 10)

                    if let message = ProtocolEngine.welcomeBackMessage(progress: progress) {
                        welcomeBack(message)
                    }

                    instrumentRow
                        .padding(.top, 30)

                    todayProtocolPlate
                        .padding(.top, 30)

                    whyToday
                        .padding(.top, 34)

                    signalBrief
                        .padding(.top, 24)

                    clarityInstrument
                        .padding(.top, 30)

                    programStrip
                        .padding(.top, 30)
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
    }

    private var systemHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                RBSystemLabel(text: "REBOOT", color: .bone)
                RBDayCounter(day: dayNumber)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("PHASE \(String(format: "%02d", plan.phase))")
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(accent)
                Text(ProtocolCurriculum.phase(forPhase: plan.phase).title)
                    .font(.metadata(size: 10))
                    .foregroundStyle(.ash)
            }
        }
    }

    private func welcomeBack(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.acid)
                .frame(width: 3, height: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text("RETOUR AU PROTOCOLE.")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(.bone)
                Text(message.replacingOccurrences(of: "WELCOME BACK.\n", with: ""))
                    .font(.metadata(size: 11))
                    .tracking(1.2)
                    .foregroundStyle(.acid)
                    .textCase(.uppercase)
            }
        }
        .padding(14)
        .background(Color.deepCarbon)
        .clipShape(RBChamferedShape(cut: 12))
        .padding(.top, 20)
    }

    private var instrumentRow: some View {
        HStack(spacing: 24) {
            RBSignalCore(day: dayNumber, total: 90, phase: plan.phase, size: 176)
            VStack(alignment: .leading, spacing: 8) {
                Text("PROGRAMME")
                    .font(.metadata(size: 10))
                    .tracking(2)
                    .foregroundStyle(.ash)
                Text("\(completedSessions) SESSIONS\nTERMINÉES")
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(.bone)
                    .lineSpacing(3)
                Text(plan.skill)
                    .font(.body(size: 13))
                    .foregroundStyle(accent)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
    }

    private var todayProtocolPlate: some View {
        RBSignalPlate(cut: 20, accent: accent, fill: .deepCarbon) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    RBModeGlyph(kind: modeGlyph, size: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AUJOURD'HUI")
                            .font(.metadata(size: 10))
                            .tracking(2)
                            .foregroundStyle(.ash)
                        Text(plan.mode.frenchLabel)
                            .font(.heroBlack(size: 34))
                            .tracking(-0.4)
                            .foregroundStyle(.bone)
                    }
                    Spacer()
                    Text("\(plan.recommendedDuration) MIN")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent)
                }

                Text(plan.mode.tagline)
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(.softBone)
                    .lineSpacing(3)
                    .padding(.top, 16)

                Text(plan.title)
                    .font(.body(size: 14))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
                    .padding(.top, 12)

                Button {
                    activeRequest = SessionRequestFactory.today(day: dayNumber)
                } label: {
                    HStack {
                        Text("COMMENCER")
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .buttonStyle(.rbSystem)
                .padding(.top, 20)
            }
            .padding(20)
        }
    }

    private var whyToday: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "WHY TODAY")
            Text(plan.whyToday)
                .font(.body(size: 17))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
                .padding(.top, 16)
        }
    }

    private var signalBrief: some View {
        RBInsightStrip(text: microInsightText, accent: .acid)
    }

    private var clarityInstrument: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "SIGNAL / CLARITY")
            HStack(spacing: 18) {
                clarityCore
                VStack(alignment: .leading, spacing: 5) {
                    Text(clarity.status.rawValue)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(clarityColor)
                        .contentTransition(.numericText())
                    if let value = clarity.value {
                        Text(String(format: "%.0f / 100", value))
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(.bone)
                            .contentTransition(.numericText())
                    } else {
                        Text(clarity.sampleSize == 0
                             ? "3 restitutions nécessaires pour le premier indice."
                             : "Indice interne basé sur de vraies restitutions.")
                            .font(.body(size: 12))
                            .foregroundStyle(.ash)
                            .lineSpacing(3)
                    }
                    Text("Indicateur interne REBOOT — pas une mesure médicale ni clinique.")
                        .font(.metadata(size: 8))
                        .tracking(0.6)
                        .foregroundStyle(.ash.opacity(0.65))
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 14))
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private var clarityCore: some View {
        if clarity.sampleSize < 3 {
            RBCalibrationCore(completed: min(3, clarity.sampleSize), size: 96)
        } else {
            ZStack {
                Circle()
                    .stroke(Color.line.opacity(0.4), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: clarity.value.map { CGFloat($0 / 100) } ?? 0)
                    .stroke(Color.signalCyan, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(clarity.value.map { String(format: "%.0f", $0) } ?? "—")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(.bone)
                    Text("CLARTÉ")
                        .font(.metadata(size: 7))
                        .tracking(1.6)
                        .foregroundStyle(.ash)
                }
            }
            .frame(width: 96, height: 96)
        }
    }

    private var programStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PROGRAMME")
                    .font(.metadata(size: 10))
                    .tracking(2)
                    .foregroundStyle(.ash)
                Spacer()
                Button {
                    showingProgram = true
                } label: {
                    Text("VOIR →")
                        .font(.metadata(size: 10))
                        .tracking(1.6)
                        .foregroundStyle(.signalCyan)
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 8) {
                ForEach(ProtocolCurriculum.phases) { phase in
                    RBPhaseBand(phase: phase.number, currentDay: dayNumber) {
                        showingProgram = true
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    private var phaseNoiseDecoration: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                ForEach(0..<noiseCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color.signalRed.opacity(0.22 - Double(index) * 0.05))
                        .frame(width: 2 + CGFloat(index % 3), height: 16 + CGFloat((index * 5) % 20))
                        .offset(
                            x: -20 - CGFloat((index * 27) % 80),
                            y: 12 + CGFloat((index * 43) % 70)
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var noiseCount: Int {
        switch plan.phase {
        case 1: return 5
        case 2: return 2
        default: return 0
        }
    }

    private var accent: Color {
        Color.phaseAccent(plan.phase)
    }

    private var modeGlyph: RBModeGlyphKind {
        switch plan.mode {
        case .stay: return .stay
        case .recall: return .recall
        case .explain: return .explain
        case .nothing: return .nothing
        case .observe: return .observe
        }
    }

    private var clarityColor: Color {
        switch clarity.status {
        case .established: return .signalCyan
        case .provisional: return .acid
        case .pendingAnalysis: return .ash
        default: return .ash
        }
    }
}
