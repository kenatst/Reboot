import SwiftUI
import SwiftData

/// 90 DAYS. ONE SYSTEM. The program as a vertical journey track.
struct ProgramView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var progressList: [RebootProgress]
    @Query private var completions: [ProtocolDayCompletion]
    @State private var expandedPhases: Set<Int> = [1]
    @State private var activeRequest: SessionRequest?

    private var progress: RebootProgress? {
        progressList.first
    }

    private var currentDay: Int {
        ProtocolEngine.currentDay(progress: progress)
    }

    private var completedDayNumbers: Set<Int> {
        Set(completions.map { $0.dayNumber })
    }

    private let milestones: Set<Int> = [7, 14, 30, 60, 90]

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            RBRadialField(color: .signalCyan, opacity: 0.04, diameter: 400)
                .position(x: UIScreen.main.bounds.width * 0.2, y: 200)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 14)

                    Text("90 JOURS.\nUN SEUL SYSTÈME.")
                        .font(.heroBlack(size: 38))
                        .tracking(-0.5)
                        .foregroundStyle(.bone)
                        .lineSpacing(-4)
                        .padding(.top, 24)

                    track
                        .padding(.top, 28)
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
        .fullScreenCover(item: $activeRequest) { request in
            SessionFlowView(request: request)
        }
    }

    private var header: some View {
        HStack {
            RBSystemLabel(text: "REBOOT / PROGRAM", color: .ash)
            Spacer()
            RBDayCounter(day: currentDay)
        }
    }

    /// Vertical track: four large phase bands, days grouped by week.
    private var track: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(ProtocolCurriculum.phases) { phase in
                phaseBand(phase)
            }
        }
    }

    private func phaseBand(_ phase: PhaseInfo) -> some View {
        let expanded = expandedPhases.contains(phase.number)
        let active = currentDay >= phase.range.lowerBound
        let current = phase.range.contains(currentDay)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(RBMotion.standardAnim) {
                    if expanded {
                        expandedPhases.remove(phase.number)
                    } else {
                        expandedPhases.insert(phase.number)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    RBTimelineNode(
                        state: current ? .current : (active ? .completed : .future),
                        size: 16
                    )
                    .frame(width: 26)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("PHASE \(String(format: "%02d", phase.number))")
                                .font(.metadata(size: 10))
                                .tracking(1.8)
                                .foregroundStyle(current ? .signalCyan : (active ? .softBone : .ash))
                            Text("JOURS \(String(format: "%02d", phase.range.lowerBound))–\(String(format: "%02d", phase.range.upperBound))")
                                .font(.metadata(size: 9))
                                .foregroundStyle(.ash.opacity(0.7))
                        }
                        Text(phase.title)
                            .font(.system(size: 18, weight: .heavy, design: .default))
                            .foregroundStyle(active ? .bone : .ash.opacity(0.5))
                        Text(phase.subtitle)
                            .font(.metadata(size: 9))
                            .tracking(1.2)
                            .foregroundStyle(active ? Color.phaseAccent(phase.number) : .ash.opacity(0.45))
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.ash)
                }
                .padding(16)
                .background(active ? Color.graphiteSurface : Color.deepCarbon)
                .clipShape(RBChamferedShape(cut: 18))
                .overlay(
                    RBChamferedShape(cut: 18)
                        .stroke(current ? Color.signalCyan.opacity(0.7) : Color.line.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if expanded {
                weekGroups(phase)
                    .padding(.leading, 30)
                    .padding(.top, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// Days grouped by week arc inside the phase.
    private func weekGroups(_ phase: PhaseInfo) -> some View {
        let weeks = Array(Set((phase.range.lowerBound...phase.range.upperBound).map { week(of: $0) })).sorted()
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(weeks, id: \.self) { week in
                VStack(alignment: .leading, spacing: 8) {
                    Text("SEMAINE \(String(format: "%02d", week))")
                        .font(.metadata(size: 9))
                        .tracking(2)
                        .foregroundStyle(.ash.opacity(0.8))
                    HStack(spacing: 0) {
                        ForEach(weekDays(phase, week: week), id: \.dayNumber) { day in
                            dayNode(day)
                        }
                    }
                }
            }
        }
    }

    private func week(of day: Int) -> Int {
        (day - 1) / 7 + 1
    }

    private func weekDays(_ phase: PhaseInfo, week: Int) -> [ProtocolDay] {
        let lower = max(phase.range.lowerBound, (week - 1) * 7 + 1)
        let upper = min(phase.range.upperBound, week * 7)
        return (lower...upper).map { ProtocolCurriculum.day($0) }
    }

    @ViewBuilder
    private func dayNode(_ day: ProtocolDay) -> some View {
        let isCurrent = day.dayNumber == currentDay
        let isDone = completedDayNumbers.contains(day.dayNumber)
        let isMilestone = milestones.contains(day.dayNumber)

        Button {
            if !(day.dayNumber > currentDay) {
                activeRequest = SessionRequestFactory.today(day: day.dayNumber)
            }
        } label: {
            VStack(spacing: 5) {
                if isCurrent {
                    ZStack {
                        Circle()
                            .fill(Color.bonePlate)
                            .frame(width: 34, height: 34)
                        Text(String(format: "%02d", day.dayNumber))
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(.ink)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.signalCyan, lineWidth: 2)
                            .frame(width: 42, height: 42)
                    )
                } else if isMilestone {
                    RBTimelineNode(state: isDone ? .milestone : .future, size: 22)
                } else {
                    RBTimelineNode(state: isDone ? .completed : .future, size: 12)
                }
                Text(String(format: "%02d", day.dayNumber))
                    .font(.metadata(size: 7))
                    .foregroundStyle(isDone || isCurrent ? .softBone : .ash.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day.dayNumber > currentDay)
    }
}
