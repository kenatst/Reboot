import SwiftUI
import SwiftData

/// PROFILE — a personal instrument panel built from real data only.
struct ProfileView: View {
    @Query private var progressList: [RebootProgress]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    @State private var showManual = false

    private var progress: RebootProgress? {
        progressList.first
    }

    private var clarity: ClarityEngine.Result {
        ClarityEngine.compute(sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.void.ignoresSafeArea()
                RBRadialField(color: .signalCyan, opacity: 0.04, diameter: 380)
                    .position(x: UIScreen.main.bounds.width * 0.8, y: 160)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        RBSystemLabel(text: "REBOOT / PROFILE", color: .ash)
                            .padding(.top, 14)

                        Text("TON ATTENTION.\nEN DONNÉES.")
                            .font(.heroBlack(size: 38))
                            .tracking(-0.4)
                            .foregroundStyle(.bone)
                            .padding(.top, 18)

                        clarityPanel
                            .padding(.top, 28)

                        matrixPanel
                            .padding(.top, 32)

                        observedPanel
                            .padding(.top, 32)

                        positionPanel
                            .padding(.top, 32)
                            .padding(.bottom, 110)
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
        .sheet(isPresented: $showManual) {
            AttentionOperatingManualView()
        }
    }

    private var clarityPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "CLARITY CORE")
            HStack(spacing: 22) {
                clarityCore
                VStack(alignment: .leading, spacing: 6) {
                    Text(clarity.status.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                        .contentTransition(.numericText())
                    if let value = clarity.value {
                        Text(String(format: "%.0f / 100", value))
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(.bone)
                            .contentTransition(.numericText())
                    }
                    Text("\(clarity.sampleSize) session\(clarity.sampleSize > 1 ? "s" : "") · confiance \(String(format: "%.0f%%", clarity.confidence * 100))")
                        .font(.metadata(size: 9))
                        .tracking(1)
                        .foregroundStyle(.ash)
                    Text("Indicateur interne REBOOT — pas une mesure médicale, neurologique, clinique ni de QI.")
                        .font(.metadata(size: 8))
                        .tracking(0.5)
                        .foregroundStyle(.ash.opacity(0.65))
                        .lineSpacing(3)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 16))
            .padding(.top, 14)
        }
    }

    @ViewBuilder
    private var clarityCore: some View {
        if clarity.sampleSize < 3 {
            RBCalibrationCore(completed: min(3, clarity.sampleSize), size: 110)
        } else {
            ZStack {
                Circle()
                    .stroke(Color.line.opacity(0.4), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: clarity.value.map { CGFloat($0 / 100) } ?? 0)
                    .stroke(Color.signalCyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(clarity.value.map { String(format: "%.0f", $0) } ?? "—")
                        .font(.system(size: 30, weight: .black, design: .monospaced))
                        .foregroundStyle(.bone)
                    Text("CLARTÉ")
                        .font(.metadata(size: 7))
                        .tracking(1.6)
                        .foregroundStyle(.ash)
                }
            }
            .frame(width: 110, height: 110)
        }
    }

    private var matrixPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "ATTENTION MATRIX")
            VStack(spacing: 16) {
                RBMetricInstrument(label: "FOCUS", value: average(scores: scored, matching: ["FOCUS", "CLARTÉ", "STRUCTURE"]))
                RBMetricInstrument(label: "STABILITÉ", value: average(scores: scored, matching: ["STABILITY", "STABILITÉ", "STRUCTURE"]))
                RBMetricInstrument(label: "RESTITUTION", value: average(scores: scored, matching: ["RECALL", "RESTITUTION", "MÉMOIRE", "CLARTÉ"]))
                RBMetricInstrument(label: "PROFONDEUR", value: average(scores: scored, matching: ["DEPTH", "PROFONDEUR", "PRÉCISION"]))
            }
            .padding(16)
            .background(Color.deepCarbon)
            .clipShape(RBChamferedShape(cut: 16))
            .padding(.top, 14)
        }
    }

    private var observedPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "OBSERVED")
            if sessions.isEmpty {
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
                        note: "Sur \(sessions.count) session\(sessions.count > 1 ? "s" : "")."
                    )
                    if sessions.count >= 3 {
                        let recent = sessions.prefix(3)
                        let older = sessions.dropFirst(3).prefix(3)
                        let delta = averageDuration(recent) - averageDuration(older)
                        insightRow(
                            title: "DURÉE",
                            value: delta >= 0 ? "+\(Int(delta)) MIN" : "\(Int(delta)) MIN",
                            note: "Comparaison entre tes \(older.count) sessions précédentes et tes \(recent.count) dernières sessions\(older.isEmpty ? " (échantillon encore petit)" : "")."
                        )
                    }
                    if sessions.count >= 2 {
                        let modeCounts = Dictionary(grouping: sessions, by: \.mode).mapValues(\.count)
                        if let top = modeCounts.max(by: { $0.value < $1.value }) {
                            insightRow(
                                title: "DISCIPLINE PRINCIPALE",
                                value: top.key.label,
                                note: "\(top.value) de tes \(sessions.count) sessions (\(Int(Double(top.value) / Double(sessions.count) * 100))%)."
                            )
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private var positionPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "90 DAY POSITION")
            HStack(spacing: 10) {
                RBDataBlock(label: "PHASE", value: "\(String(format: "%02d", currentPhase))")
                RBDataBlock(label: "SESSIONS", value: "\(progress?.completedSessions ?? 0)")
                RBDataBlock(label: "MINUTES", value: "\(sessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60)")
            }
            .padding(.top, 14)
            HStack(spacing: 10) {
                RBDataBlock(label: "DISCIPLINES", value: "\(Set(sessions.map(\.mode)).count)")
                RBDataBlock(label: "CLARTÉ", value: clarity.value.map { String(format: "%.0f", $0) } ?? clarity.status.rawValue)
            }
            .padding(.top, 10)

            Button {
                showManual = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(.signalCyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MANUEL OPÉRATOIRE D'ATTENTION")
                            .font(.metadata(size: 9))
                            .tracking(1.4)
                            .foregroundStyle(.signalCyan)
                        Text("Consulter la synthèse de tes données et règles")
                            .font(.body(size: 12))
                            .foregroundStyle(.bone)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.ash)
                }
                .padding(14)
                .background(Color.deepCarbon)
                .clipShape(RBChamferedShape(cut: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
    }

    private var scored: [EvaluationResult] {
        sessions.compactMap { $0.evaluation }
    }

    private var currentPhase: Int {
        ProtocolEngine.phaseNumber(forDay: ProtocolEngine.currentDay(progress: progress))
    }

    private func average(scores: [EvaluationResult], matching names: [String]) -> Double? {
        let values = scores.flatMap(\.dimensions)
            .filter { dimension in
                names.contains { dimension.name.uppercased().contains($0) }
            }
            .map(\.score)
        guard !values.isEmpty else { return nil }
        return (values.reduce(0, +) / Double(values.count) * 10).rounded() / 10
    }

    private func averageDuration(_ items: ArraySlice<TrainingSession>) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.reduce(0) { $0 + $1.actualDurationSeconds }) / Double(items.count) / 60.0
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

    private var statusColor: Color {
        switch clarity.status {
        case .established: return .signalCyan
        case .provisional: return .acid
        case .pendingAnalysis: return .ash
        default: return .ash
        }
    }
}
