import SwiftUI
import SwiftData

/// Weekly signal review — real week data, one insight, three questions.
struct CheckpointView: View {
    let week: Int
    var onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    @State private var answers: [String] = ["", "", ""]
    @State private var saved = false

    private var template: WeeklyCheckpointTemplate? {
        ContentStore.checkpoint(week: week)
    }

    private var weekSessions: [TrainingSession] {
        let start = max(0, sessions.count - 7)
        return Array(sessions.dropFirst(start))
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBStatusChip(text: "REBOOT CHECKPOINT \(String(format: "%02d", week))", color: .signalCyan, pulse: false)
                        .padding(.top, 34)

                    Text(template?.title ?? "LE POINT")
                        .font(.heroBlack(size: 40))
                        .foregroundStyle(.bone)
                        .padding(.top, 24)

                    weekData
                        .padding(.top, 26)

                    if let insight = template?.insight {
                        RBInsightStrip(text: insight, accent: .signalCyan)
                            .padding(.top, 24)
                    }

                    if let questions = template?.questions {
                        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                            questionField(title: question, text: $answers[index])
                                .padding(.top, 24)
                        }
                    }

                    if let objective = template?.objective {
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(Color.acid)
                                .frame(width: 3, height: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("OBJECTIF DE LA SEMAINE PROCHAINE")
                                    .font(.metadata(size: 9))
                                    .tracking(1.6)
                                    .foregroundStyle(.ash)
                                Text(objective)
                                    .font(.body(size: 14))
                                    .foregroundStyle(.softBone)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(14)
                        .background(Color.deepCarbon)
                        .clipShape(RBChamferedShape(cut: 12))
                        .padding(.top, 26)
                    }

                    Button {
                        save()
                        onContinue()
                    } label: {
                        HStack {
                            Text("CONTINUER")
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
            .scrollDismissesKeyboard(.interactively)
        }
        .statusBarHidden()
    }

    private var weekData: some View {
        HStack(spacing: 10) {
            RBDataBlock(label: "SESSIONS", value: "\(weekSessions.count)")
            RBDataBlock(label: "MINUTES", value: "\(weekSessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60)")
            RBDataBlock(label: "MODE", value: weekSessions.first?.mode.label ?? "—")
        }
    }

    private func questionField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.metadata(size: 11))
                .tracking(1.4)
                .foregroundStyle(.ash)
            TextField("Écris ce qui est vrai pour toi…", text: text, axis: .vertical)
                .font(.body(size: 15))
                .foregroundStyle(.bone)
                .lineLimit(3...5)
                .padding(14)
                .background(Color.deepCarbon)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.line, lineWidth: 1)
                )
        }
    }

    private func save() {
        guard !saved else { return }
        modelContext.insert(
            WeeklyCheckpoint(
                weekNumber: week,
                biggestDistraction: answers.indices.contains(0) ? answers[0] : "",
                easierNow: answers.indices.contains(1) ? answers[1] : "",
                controlTarget: answers.indices.contains(2) ? answers[2] : "",
                sessionsInWeek: weekSessions.count
            )
        )
        try? modelContext.save()
        saved = true
    }
}
