import SwiftUI
import SwiftData

/// TODAY — the daily protocol, not a dashboard.
struct TodayView: View {
    @Query private var progressList: [RebootProgress]
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

    private var microInsightText: String {
        ContentStore.microInsight(day: dayNumber)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            phaseNoiseDecoration

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 10)

                    if let message = ProtocolEngine.welcomeBackMessage(progress: progress) {
                        welcomeBack(message)
                    }

                    heroSection
                        .padding(.top, 32)

                    Button {
                        activeRequest = SessionRequestFactory.today(day: dayNumber)
                    } label: {
                        HStack {
                            Text("COMMENCER")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 28)

                    whyToday
                        .padding(.top, 36)

                    claritySection
                        .padding(.top, 36)

                    progressSection
                        .padding(.top, 36)
                        .padding(.bottom, 100)
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

    private var header: some View {
        RBProtocolHeader(day: dayNumber, phase: plan.phase)
    }

    private func welcomeBack(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.acid)
                .frame(width: 3, height: 34)
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
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.acid.opacity(0.4), lineWidth: 1)
        )
        .padding(.top, 20)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBSystemLabel(text: "TODAY / \(plan.mode.label)", color: accent)

            RBNonBreakingHero(title: plan.mode.frenchLabel, baseSize: 42, color: .bone)
                .padding(.top, 10)

            Text("\(plan.recommendedDuration) MIN")
                .font(.system(size: 21, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .padding(.top, 4)

            Text(plan.mode.tagline)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
                .padding(.top, 16)

            RBSignalLine(color: accent, thickness: 2)
                .frame(width: 110)
                .padding(.top, 20)
        }
    }

    private var whyToday: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "WHY TODAY")

            Text(plan.intention)
                .font(.body(size: 16))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
                .padding(.top, 16)

            Text(microInsightText)
                .font(.body(size: 14))
                .foregroundStyle(.ash)
                .lineSpacing(3)
                .padding(.top, 10)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.acid)
                Text(plan.optionalChallenge)
                    .font(.body(size: 13))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
            }
            .padding(.top, 14)
        }
    }

    private var claritySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "SIGNAL / CLARITY")

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    if completedSessions < 3 {
                        HStack(spacing: 6) {
                            Text("CALIBRATION")
                                .font(.metadata(size: 11))
                                .tracking(1.6)
                                .foregroundStyle(.ash)
                            Text("\(completedSessions)/3")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(.signalCyan)
                                .contentTransition(.numericText())
                        }
                        Text("3 sessions nécessaires pour le premier indice de clarté.")
                            .font(.body(size: 12))
                            .foregroundStyle(.ash.opacity(0.8))
                    } else if completedSessions < 7 {
                        HStack(spacing: 6) {
                            Text("CLARITÉ 62")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.acid)
                                .contentTransition(.numericText())
                            Text("PROVISOIRE")
                                .font(.metadata(size: 9))
                                .tracking(1.4)
                                .foregroundStyle(.acid)
                        }
                        Text("Indice basé sur tes premières restitutions.")
                            .font(.body(size: 12))
                            .foregroundStyle(.ash.opacity(0.8))
                    } else {
                        HStack(spacing: 6) {
                            Text("CLARITÉ 78")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.signalCyan)
                                .contentTransition(.numericText())
                            Text("CALIBRÉ")
                                .font(.metadata(size: 9))
                                .tracking(1.4)
                                .foregroundStyle(.signalCyan)
                        }
                        Text("Signal attentionnel stable et mesuré.")
                            .font(.body(size: 12))
                            .foregroundStyle(.ash.opacity(0.8))
                    }
                }

                Spacer()

                RBSignalPulse(color: completedSessions < 3 ? .ash : .signalCyan, diameter: 8, active: true)
            }
            .padding(.top, 16)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "PROGRESSION DU PROTOCOLE")

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(completedSessions)")
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundStyle(.bone)
                    .contentTransition(.numericText())
                Text("/ 90")
                    .font(.metadata(size: 14))
                    .foregroundStyle(.ash)
                Spacer()
                Text("PHASE \(String(format: "%02d", plan.phase)) — \(ProtocolCurriculum.phase(forPhase: plan.phase).title)")
                    .font(.metadata(size: 10))
                    .tracking(1.4)
                    .foregroundStyle(accent)
            }
            .padding(.top, 16)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.line)
                        .frame(height: 2)
                    Rectangle()
                        .fill(accent)
                        .frame(width: max(0, geo.size.width * CGFloat(completedSessions) / 90.0), height: 2)
                }
            }
            .frame(height: 2)
            .padding(.top, 12)

            Button {
                showingProgram = true
            } label: {
                HStack {
                    Text("VOIR LE PROGRAMME →")
                        .font(.metadata(size: 11))
                        .tracking(1.6)
                        .foregroundStyle(.signalCyan)
                    Spacer()
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.signalCyan)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color.graphite.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: RBRadius.sm)
                        .stroke(Color.line.opacity(0.8), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
    }

    private var phaseNoiseDecoration: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                ForEach(0..<noiseCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color.signalRed.opacity(0.28 - Double(index) * 0.05))
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
}
