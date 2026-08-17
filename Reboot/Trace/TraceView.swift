import SwiftUI
import SwiftData
import Charts

/// TRACE — a continuous signal line of real sessions.
struct TraceView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @State private var selected: TrainingSession?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBSystemLabel(text: "REBOOT / TRACE", color: .ash)
                        .padding(.top, 14)

                    Text("CE QUE\nTU AS\nENTRAÎNÉ.")
                        .font(.heroBlack(size: 40))
                        .tracking(-0.4)
                        .foregroundStyle(.bone)
                        .padding(.top, 18)

                    if sessions.isEmpty {
                        emptyState
                            .padding(.top, 44)
                    } else {
                        if sessions.count >= 4 {
                            signalGraph
                                .padding(.top, 30)
                        }

                        signalTimeline
                            .padding(.top, 30)
                            .padding(.bottom, 110)
                    }
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .sheet(item: $selected) { session in
            TraceDetailView(session: session)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.void)
        }
        .onAppear {
            #if DEBUG
            if UITestDriver.autoTour, selected == nil {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if let first = sessions.first {
                        selected = first
                    }
                }
            }
            #endif
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBTimelineNode(state: .current, size: 18)
            Text("AUCUNE SESSION\nPOUR L'INSTANT.")
                .font(.system(size: 24, weight: .heavy, design: .default))
                .foregroundStyle(.softBone)
                .lineSpacing(3)
                .padding(.top, 18)
            Text("Le trace ne se remplit qu'avec de vraies sessions. Commence le jour 001 : tout ce qui sera écrit ici sera réel.")
                .font(.body(size: 15))
                .foregroundStyle(.ash)
                .lineSpacing(4)
                .padding(.top, 12)
        }
    }

    private var signalTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        RBTimelineNode(state: nodeState(session), size: 13)
                        if index < sessions.count - 1 {
                            Rectangle()
                                .fill(Color.line.opacity(0.6))
                                .frame(width: 1.5, height: 74)
                        }
                    }

                    Button {
                        selected = session
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 10) {
                                    Text("DAY \(String(format: "%03d", session.protocolDay))")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(modeColor(session.mode))
                                    Text(session.formattedDate)
                                        .font(.metadata(size: 9))
                                        .foregroundStyle(.ash)
                                }
                                Text(session.mode.frenchLabel)
                                    .font(.system(size: 16, weight: .heavy, design: .default))
                                    .foregroundStyle(.bone)
                                if !session.task.isEmpty && session.mode == .stay {
                                    Text(session.task)
                                        .font(.body(size: 13))
                                        .foregroundStyle(.softBone)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(session.actualDurationSeconds / 60) MIN")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.ash)
                                if let evaluation = session.evaluation {
                                    Text(String(format: "%.0f/10", evaluation.overallScore))
                                        .font(.system(size: 15, weight: .black, design: .monospaced))
                                        .foregroundStyle(.signalCyan)
                                } else if session.analysisOffline {
                                    Text("OFFLINE")
                                        .font(.metadata(size: 9))
                                        .foregroundStyle(.acid)
                                } else {
                                    Text("—")
                                        .font(.metadata(size: 12))
                                        .foregroundStyle(.ash.opacity(0.5))
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func nodeState(_ session: TrainingSession) -> RBTimelineNode.NodeState {
        session.evaluation != nil ? .completed : .future
    }

    private func modeColor(_ mode: SessionMode) -> Color {
        switch mode {
        case .stay: return .signalCyan
        case .recall: return .softBone
        case .explain: return .acid
        case .nothing: return .ash
        case .observe: return .signalRed
        }
    }

    private var signalGraph: some View {
        let scored = sessions.compactMap { session -> (date: Date, score: Double)? in
            guard let evaluation = session.evaluation else { return nil }
            return (session.date, evaluation.overallScore)
        }

        return VStack(alignment: .leading, spacing: 16) {
            if !scored.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("SCORES / SESSION")
                        .font(.metadata(size: 10))
                        .tracking(2)
                        .foregroundStyle(.ash)
                    Chart(scored, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(Color.signalCyan)
                        .interpolationMethod(.monotone)
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(Color.signalCyan)
                    }
                    .chartYScale(domain: 0...10)
                    .frame(height: 130)
                }
                .padding(14)
                .background(Color.graphiteSurface)
                .clipShape(RBChamferedShape(cut: 14))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("MINUTES / SEMAINE")
                    .font(.metadata(size: 10))
                    .tracking(2)
                    .foregroundStyle(.ash)
                Chart(weeklyMinutes()) { item in
                    BarMark(
                        x: .value("Semaine", item.week),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(Color.signalRed.opacity(0.8))
                }
                .frame(height: 100)
            }
            .padding(14)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 14))
        }
    }

    private func weeklyMinutes() -> [WeekMinutes] {
        let calendar = Calendar.current
        var buckets: [Int: Int] = [:]
        for session in sessions {
            let week = calendar.component(.weekOfYear, from: session.date)
            buckets[week, default: 0] += session.actualDurationSeconds / 60
        }
        return buckets
            .map { WeekMinutes(week: $0.key, minutes: $0.value) }
            .sorted { $0.week < $1.week }
            .suffix(8)
    }
}

struct WeekMinutes: Identifiable {
    let week: Int
    let minutes: Int
    var id: Int { week }
}

struct TraceDetailView: View {
    let session: TrainingSession

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        RBSystemLabel(text: "REBOOT / TRACE", color: .ash)
                        Spacer()
                        RBDayCounter(day: session.protocolDay)
                    }
                    .padding(.top, 18)

                    Text(session.mode.frenchLabel)
                        .font(.heroBlack(size: 38))
                        .foregroundStyle(.bone)
                        .padding(.top, 20)

                    Text("\(session.formattedDate) · \(session.actualDurationSeconds / 60) MIN")
                        .font(.metadata(size: 11))
                        .tracking(1.2)
                        .foregroundStyle(.ash)
                        .padding(.top, 6)

                    if !session.task.isEmpty && session.mode == .stay {
                        Text(session.task)
                            .font(.body(size: 15))
                            .foregroundStyle(.softBone)
                            .padding(.top, 16)
                    }

                    if session.mode == .stay {
                        HStack {
                            Text("SWITCHES")
                                .font(.metadata(size: 11))
                                .tracking(2)
                                .foregroundStyle(.ash)
                            Spacer()
                            Text("\(session.switchedCount)")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(session.switchedCount > 0 ? .signalRed : .signalCyan)
                        }
                        .padding(.top, 20)
                    }

                    if let evaluation = session.evaluation {
                        RBResultMetric(score: evaluation.overallScore, label: "SESSION / ANALYZED")
                            .padding(.top, 30)
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(evaluation.dimensions) { dimension in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(dimension.name)
                                        .font(.metadata(size: 11))
                                        .tracking(2)
                                        .foregroundStyle(.ash)
                                    Spacer()
                                    Text(String(format: "%.0f/10", dimension.score))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.signalCyan)
                                }
                            }
                        }
                        .padding(.top, 20)
                    } else if session.analysisOffline {
                        RBStatusChip(text: "ANALYSIS OFFLINE", color: .acid)
                            .padding(.top, 26)
                    }

                    if !session.userResponse.isEmpty {
                        RBEditorialDivider(label: "RESTITUTION")
                            .padding(.top, 30)
                        Text(session.userResponse)
                            .font(.reading(size: 17))
                            .foregroundStyle(.softBone)
                            .lineSpacing(6)
                            .padding(.top, 14)
                    }

                    if session.calm != nil || session.energy != nil {
                        HStack(spacing: 26) {
                            if let calm = session.calm {
                                labelValue("CALME", "\(calm)/5")
                            }
                            if let energy = session.energy {
                                labelValue("ÉNERGIE", "\(energy)/5")
                            }
                            Spacer()
                        }
                        .padding(.top, 26)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
    }

    private func labelValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.metadata(size: 10))
                .tracking(2)
                .foregroundStyle(.ash)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.bone)
        }
    }
}
