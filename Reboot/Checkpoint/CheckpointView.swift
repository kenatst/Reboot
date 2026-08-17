import SwiftUI
import SwiftData

/// Weekly checkpoints — every 7 completed protocol sessions. No trophies.
struct CheckpointView: View {
    let week: Int
    var onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    @State private var distraction = ""
    @State private var easier = ""
    @State private var control = ""
    @State private var saved = false

    private var weekSessions: [TrainingSession] {
        let start = max(0, sessions.count - 7)
        return Array(sessions.dropFirst(start))
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBStatusChip(text: "REBOOT CHECKPOINT \(String(format: "%02d", week))", color: .signalCyan, pulse: true)
                        .padding(.top, 34)

                    Text("OÙ EN EST\nTON ATTENTION ?")
                        .font(.heroBlack(size: 40))
                        .foregroundStyle(.bone)
                        .padding(.top, 24)

                    weekData
                        .padding(.top, 26)

                    questionField(
                        title: "QU'EST-CE QUI TE DISTRAIT LE PLUS ?",
                        text: $distraction
                    )
                    .padding(.top, 28)

                    questionField(
                        title: "QU'EST-CE QUI DEVIENT PLUS FACILE ?",
                        text: $easier
                    )
                    .padding(.top, 22)

                    questionField(
                        title: "OÙ VEUX-TU MIEUX CONTRÔLER TON ATTENTION ?",
                        text: $control
                    )
                    .padding(.top, 22)

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
                    .buttonStyle(.rbPrimary())
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
        VStack(alignment: .leading, spacing: 10) {
            Text("SEMAINE RÉELLE")
                .font(.metadata(size: 10))
                .tracking(2)
                .foregroundStyle(.ash)
            HStack(spacing: 26) {
                stat("SESSIONS", "\(weekSessions.count)")
                stat("MINUTES", "\(weekSessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60)")
                stat("MODE PRINCIPAL", weekSessions.first?.mode.label ?? "—")
            }
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.metadata(size: 9))
                .tracking(1.6)
                .foregroundStyle(.ash)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.bone)
        }
    }

    private func questionField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.metadata(size: 11))
                .tracking(1.6)
                .foregroundStyle(.ash)
            TextField("Écris ce qui est vrai pour toi…", text: text, axis: .vertical)
                .font(.body(size: 15))
                .foregroundStyle(.bone)
                .lineLimit(3...6)
                .padding(14)
                .overlay(
                    RoundedRectangle(cornerRadius: RBRadius.sm)
                        .stroke(Color.line, lineWidth: 1)
                )
        }
    }

    private func save() {
        guard !saved else { return }
        modelContext.insert(
            WeeklyCheckpoint(
                weekNumber: week,
                biggestDistraction: distraction,
                easierNow: easier,
                controlTarget: control,
                sessionsInWeek: weekSessions.count
            )
        )
        try? modelContext.save()
        saved = true
    }
}
