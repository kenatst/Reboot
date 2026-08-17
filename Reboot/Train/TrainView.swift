import SwiftUI
import SwiftData

/// TRAIN — the five disciplines and the full 90-day curriculum.
struct TrainView: View {
    @Query private var progressList: [RebootProgress]
    @Query private var completions: [ProtocolDayCompletion]
    @State private var activeRequest: SessionRequest?
    @State private var showCurriculum = false

    private var progress: RebootProgress? {
        progressList.first
    }

    private var dayNumber: Int {
        ProtocolEngine.currentDay(progress: progress)
    }

    private var completedDays: Set<Int> {
        Set(completions.map(\.dayNumber))
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBProtocolHeader(day: dayNumber, phase: ProtocolCurriculum.day(dayNumber).phase)
                        .padding(.top, 10)

                    Text("CHOISIS TON\nENTRAÎNEMENT.")
                        .font(.heroBlack(size: 38))
                        .tracking(-0.5)
                        .foregroundStyle(.bone)
                        .lineSpacing(-4)
                        .padding(.top, 28)

                    Button {
                        activeRequest = SessionRequestFactory.today(day: dayNumber)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RECOMMANDÉ AUJOURD'HUI")
                                    .font(.metadata(size: 10))
                                    .tracking(2)
                                    .foregroundStyle(.signalCyan)
                                Text("JOUR \(String(format: "%03d", dayNumber)) — \(ProtocolCurriculum.day(dayNumber).mode.frenchLabel) · \(ProtocolCurriculum.day(dayNumber).recommendedDuration) MIN")
                                    .font(.system(size: 15, weight: .bold, design: .default))
                                    .foregroundStyle(.bone)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.signalCyan)
                        }
                        .padding(18)
                        .background(Color.graphite.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: RBRadius.sm)
                                .stroke(Color.signalCyan.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 22)

                    Text("LES 5 DISCIPLINES")
                        .font(.metadata(size: 11))
                        .tracking(2)
                        .foregroundStyle(.ash)
                        .padding(.top, 32)

                    VStack(spacing: 12) {
                        ForEach(Array(SessionMode.allCases.enumerated()), id: \.element) { index, mode in
                            Button {
                                activeRequest = SessionRequestFactory.discipline(mode, day: dayNumber)
                            } label: {
                                RBSessionRow(index: index + 1, mode: mode, accent: disciplineAccent(mode))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 12)

                    HStack {
                        Text("PROGRAMME COMPLET")
                            .font(.metadata(size: 11))
                            .tracking(2)
                            .foregroundStyle(.ash)
                        Spacer()
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showCurriculum.toggle()
                            }
                        } label: {
                            Text(showCurriculum ? "MASQUER" : "VOIR LES 90 JOURS")
                                .font(.metadata(size: 10))
                                .tracking(1.4)
                                .foregroundStyle(.signalCyan)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 34)

                    if showCurriculum {
                        curriculum
                            .padding(.top, 14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, 100)
            }
        }
        .fullScreenCover(item: $activeRequest) { request in
            SessionFlowView(request: request)
        }
    }

    private var curriculum: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(ProtocolCurriculum.phases) { phase in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text(String(format: "PHASE %02d", phase.number))
                            .font(.metadata(size: 11))
                            .tracking(1.8)
                            .foregroundStyle(phase.number <= 2 ? .signalRed : .signalCyan)
                        Rectangle()
                            .fill(Color.line)
                            .frame(height: 1)
                            .frame(maxWidth: 24)
                        Text(phase.title)
                            .font(.system(size: 15, weight: .bold, design: .default))
                            .foregroundStyle(.softBone)
                        Spacer()
                        Text("JOURS \(String(format: "%02d", phase.range.lowerBound))–\(String(format: "%02d", phase.range.upperBound))")
                            .font(.metadata(size: 9))
                            .foregroundStyle(.ash)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(Array(phase.range), id: \.self) { number in
                            let plan = ProtocolCurriculum.day(number)
                            RBProtocolCard(
                                day: plan,
                                isToday: number == self.dayNumber,
                                isCompleted: completedDays.contains(number)
                            )
                        }
                    }
                }
            }
        }
    }

    private func disciplineAccent(_ mode: SessionMode) -> Color {
        switch mode {
        case .stay: return .signalCyan
        case .recall, .explain: return .softBone
        case .nothing: return .ash
        case .observe: return .signalRed
        }
    }
}
