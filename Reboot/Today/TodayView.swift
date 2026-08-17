import SwiftUI
import SwiftData

/// TODAY — the daily protocol, not a dashboard.
struct TodayView: View {
    @Query private var progressList: [RebootProgress]
    @State private var activeRequest: SessionRequest?

    private var progress: RebootProgress? {
        progressList.first
    }

    private var dayNumber: Int {
        ProtocolEngine.currentDay(progress: progress)
    }

    private var plan: ProtocolDay {
        ProtocolCurriculum.day(dayNumber)
    }

    private var clarity: ProtocolEngine.ClarityStatus {
        ProtocolEngine.clarityStatus(sessionsCompleted: progress?.completedSessions ?? 0)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            phaseNoiseDecoration

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if let message = ProtocolEngine.welcomeBackMessage(progress: progress) {
                        welcomeBack(message)
                    }

                    heroSection
                        .padding(.top, 36)

                    Button {
                        activeRequest = SessionRequestFactory.today(day: dayNumber)
                    } label: {
                        HStack {
                            Text("START PROTOCOL")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 30)

                    whyToday
                        .padding(.top, 38)

                    claritySection
                        .padding(.top, 38)

                    progressSection
                        .padding(.top, 38)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .fullScreenCover(item: $activeRequest) { request in
            SessionFlowView(request: request)
        }
    }

    private var header: some View {
        RBProtocolHeader(day: dayNumber, phase: plan.phase)
            .padding(.top, 14)
    }

    private func welcomeBack(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.acid)
                .frame(width: 3, height: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text("WELCOME BACK.")
                    .font(.system(size: 15, weight: .bold, design: .default))
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
        .padding(.top, 24)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBSystemLabel(text: "TODAY", color: accent)

            Text(plan.mode.frenchLabel)
                .font(.heroBlack(size: 44))
                .tracking(-0.4)
                .foregroundStyle(.bone)
                .padding(.top, 10)

            Text("\(plan.recommendedDuration) MIN")
                .font(.system(size: 21, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .padding(.top, 4)

            Text(plan.mode.tagline)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
                .padding(.top, 18)

            RBSignalLine(color: accent, thickness: 2)
                .frame(width: 110)
                .padding(.top, 22)
        }
    }

    private var whyToday: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "WHY TODAY")
            Text(plan.intention)
                .font(.body(size: 17))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
                .padding(.top, 18)

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
            HStack {
                Text(clarity.label)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(clarityColor)
                Spacer()
                RBSignalPulse(color: .signalCyan, diameter: 7, active: true)
            }
            .padding(.top, 16)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "PROTOCOL PROGRESS")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(progress?.completedSessions ?? 0)")
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundStyle(.bone)
                Text("/ 90")
                    .font(.metadata(size: 14))
                    .foregroundStyle(.ash)
                Spacer()
                Text(progress?.coreModeUnlocked == true ? "CORE MODE" : "PHASE \(String(format: "%02d", plan.phase))")
                    .font(.metadata(size: 10))
                    .tracking(1.6)
                    .foregroundStyle(accent)
            }
            .padding(.top, 18)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.line)
                        .frame(height: 2)
                    Rectangle()
                        .fill(accent)
                        .frame(width: geo.size.width * CGFloat(progress?.completedSessions ?? 0) / 90.0, height: 2)
                }
            }
            .frame(height: 2)
            .padding(.top, 14)

            RBProgressTimeline(currentDay: dayNumber)
                .padding(.top, 18)
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
        case 1: return 6
        case 2: return 3
        case 3: return 1
        default: return 0
        }
    }

    private var accent: Color {
        Color.phaseAccent(plan.phase)
    }

    private var clarityColor: Color {
        switch clarity {
        case .empty, .calibrating: return .ash
        case .provisional: return .acid
        case .normal: return .signalCyan
        }
    }
}
