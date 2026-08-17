import SwiftUI
import SwiftData

/// PROFILE — your attention in data, with honest sample sizes.
struct ProfileView: View {
    @Query private var progressList: [RebootProgress]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    private var progress: RebootProgress? {
        progressList.first
    }

    private var clarity: ProtocolEngine.ClarityStatus {
        ProtocolEngine.clarityStatus(sessionsCompleted: progress?.completedSessions ?? 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.void.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        RBSystemLabel(text: "REBOOT / PROFILE", color: .ash)
                            .padding(.top, 14)

                        Text("YOUR\nATTENTION\nIN DATA.")
                            .font(.heroBlack(size: 40))
                            .tracking(-0.4)
                            .foregroundStyle(.bone)
                            .padding(.top, 18)

                        claritySection
                            .padding(.top, 30)

                        dimensionsSection
                            .padding(.top, 34)

                        observedSection
                            .padding(.top, 34)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, RBSpacing.screen)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.ash)
                    }
                }
            }
        }
    }

    private var claritySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "CLARITY")
            HStack(alignment: .firstTextBaseline) {
                Text(clarity.label)
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundStyle(clarityColor)
                Spacer()
                Text("INTERNE")
                    .font(.metadata(size: 9))
                    .tracking(1.6)
                    .foregroundStyle(.ash)
            }
            .padding(.top, 16)
        }
    }

    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "DIMENSIONS")
            VStack(spacing: 0) {
                ForEach(dimensionRows, id: \.label) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.label)
                            .font(.metadata(size: 12))
                            .tracking(2)
                            .foregroundStyle(.ash)
                        Spacer()
                        Text(row.value)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(row.color)
                    }
                    .padding(.vertical, 13)
                    if row.label != dimensionRows.last?.label {
                        Rectangle()
                            .fill(Color.line.opacity(0.7))
                            .frame(height: 1)
                    }
                }
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: RBRadius.sm)
                    .stroke(Color.line, lineWidth: 1)
            )
            .padding(.top, 16)
        }
    }

    private var observedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "OBSERVED")

            let count = sessions.count
            if count == 0 {
                Text("Aucune donnée pour l'instant. Le profil se construit avec de vraies sessions.")
                    .font(.body(size: 15))
                    .foregroundStyle(.ash)
                    .lineSpacing(4)
                    .padding(.top, 16)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    insightRow(
                        title: "TEMPS TOTAL",
                        value: "\(sessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60) MIN",
                        note: "Sur tes \(count) session\(count > 1 ? "s" : "")."
                    )
                    if count >= 3 {
                        let recent = sessions.prefix(3)
                        let older = sessions.dropFirst(3).prefix(3)
                        let recentAvg = averageDuration(recent)
                        let olderAvg = averageDuration(older)
                        let delta = recentAvg - olderAvg
                        insightRow(
                            title: "DURÉE",
                            value: delta >= 0 ? "+\(Int(delta)) MIN" : "\(Int(delta)) MIN",
                            note: "Comparaison entre tes \(older.count) sessions précédentes et tes \(recent.count) dernières sessions\(older.isEmpty ? " (échantillon encore petit)" : "")."
                        )
                    }
                    if count >= 2 {
                        let modeCounts = Dictionary(grouping: sessions, by: \.mode).mapValues(\.count)
                        let top = modeCounts.max { $0.value < $1.value }
                        if let top {
                            insightRow(
                                title: "DISCIPLINE",
                                value: top.key.label,
                                note: "\(top.value) de tes \(count) sessions (\(Int(Double(top.value) / Double(count) * 100))%)."
                            )
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private func insightRow(title: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.metadata(size: 10))
                .tracking(2)
                .foregroundStyle(.ash)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.bone)
            Text(note)
                .font(.body(size: 13))
                .foregroundStyle(.ash)
                .lineSpacing(3)
        }
        .padding(.vertical, 4)
    }

    private func averageDuration(_ items: ArraySlice<TrainingSession>) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.reduce(0) { $0 + $1.actualDurationSeconds }) / Double(items.count) / 60.0
    }

    private var dimensionRows: [DimensionRow] {
        let scored = sessions.compactMap { $0.evaluation }

        func row(_ label: String, _ value: Double?) -> DimensionRow {
            DimensionRow(
                label: label,
                value: value.map { String(format: "%.1f/10", $0) } ?? "—",
                color: value.map { _ in Color.signalCyan } ?? .ash.opacity(0.6)
            )
        }
        return [
            row("FOCUS", average(scores: scored, matching: ["FOCUS", "CLARTÉ", "STRUCTURE"])),
            row("STABILITÉ", average(scores: scored, matching: ["STABILITY", "STABILITÉ", "STRUCTURE"])),
            row("RESTITUTION", average(scores: scored, matching: ["RECALL", "RESTITUTION", "MÉMOIRE", "CLARTÉ"])),
            row("PROFONDEUR", average(scores: scored, matching: ["DEPTH", "PROFONDEUR", "PRÉCISION"]))
        ]
    }

    private func average(scores: [EvaluationResult], matching names: [String]) -> Double? {
        let values = scores.flatMap(\.dimensions)
            .filter { dimension in
                names.contains { dimension.name.uppercased().contains($0) }
            }
            .map(\.score)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var clarityColor: Color {
        switch clarity {
        case .empty, .calibrating: return .ash
        case .provisional: return .acid
        case .normal: return .signalCyan
        }
    }
}

private struct DimensionRow {
    let label: String
    let value: String
    let color: Color
}
