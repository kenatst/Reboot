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

    private var completedSessions: Int {
        progress?.completedSessions ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.void.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            RBSystemLabel(text: "REBOOT / PROFILE", color: .ash)
                            Spacer()
                        }
                        .padding(.top, 10)

                        Text("TON ATTENTION.\nEN DONNÉES.")
                            .font(.heroBlack(size: 38))
                            .tracking(-0.5)
                            .foregroundStyle(.bone)
                            .lineSpacing(-4)
                            .padding(.top, 20)

                        claritySection
                            .padding(.top, 30)

                        dimensionsSection
                            .padding(.top, 34)

                        observedSection
                            .padding(.top, 34)
                            .padding(.bottom, 100)
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
                            .foregroundStyle(.bone)
                    }
                }
            }
        }
    }

    private var claritySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "INDICE DE CLARTÉ")

            HStack(alignment: .firstTextBaseline) {
                if completedSessions < 3 {
                    HStack(spacing: 8) {
                        Text("CALIBRATION")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(.ash)
                        Text("\(completedSessions)/3")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(.signalCyan)
                            .contentTransition(.numericText())
                    }
                } else if completedSessions < 7 {
                    HStack(spacing: 8) {
                        Text("CLARITÉ 62")
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundStyle(.acid)
                        Text("PROVISOIRE")
                            .font(.metadata(size: 10))
                            .tracking(1.4)
                            .foregroundStyle(.acid)
                    }
                } else {
                    HStack(spacing: 8) {
                        Text("CLARITÉ 78")
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundStyle(.signalCyan)
                        Text("CALIBRÉ")
                            .font(.metadata(size: 10))
                            .tracking(1.4)
                            .foregroundStyle(.signalCyan)
                    }
                }

                Spacer()
                Text("DONNÉES LOCALES")
                    .font(.metadata(size: 9))
                    .tracking(1.4)
                    .foregroundStyle(.ash)
            }
            .padding(.top, 16)
        }
    }

    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "DIMENSIONS COGNITIVES")

            let scored = sessions.compactMap { $0.evaluation }
            let focusScore = average(scores: scored, matching: ["FOCUS", "CLARTÉ", "STRUCTURE"])
            let stabilityScore = average(scores: scored, matching: ["STABILITY", "STABILITÉ", "STRUCTURE"])
            let recallScore = average(scores: scored, matching: ["RECALL", "RESTITUTION", "MÉMOIRE", "CLARTÉ"])
            let depthScore = average(scores: scored, matching: ["DEPTH", "PROFONDEUR", "PRÉCISION"])

            VStack(spacing: 12) {
                RBSignalRail(
                    label: "FOCUS",
                    score: focusScore,
                    note: focusScore != nil ? "Capacité de maintien sur une cible sans déviation." : "Nécessite des sessions Stay."
                )

                RBSignalRail(
                    label: "STABILITÉ",
                    score: stabilityScore,
                    note: stabilityScore != nil ? "Résistance aux interruptions et retours rapides." : "Nécessite des sessions régulières."
                )

                RBSignalRail(
                    label: "RESTITUTION",
                    score: recallScore,
                    note: recallScore != nil ? "Fidélité de la mémoire de travail après fermeture." : "Nécessite des sessions Recall."
                )

                RBSignalRail(
                    label: "PROFONDEUR",
                    score: depthScore,
                    note: depthScore != nil ? "Compréhension structurelle et capacité d'explication." : "Nécessite des sessions Explain."
                )
            }
            .padding(.top, 16)
        }
    }

    private var observedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "OBSERVATIONS DERIVÉES")

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
                        title: "TEMPS TOTAL ENTRAÎNÉ",
                        value: "\(sessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60) MIN",
                        note: "Basé sur \(count) session\(count > 1 ? "s" : "") réelles complétées."
                    )
                    if count >= 3 {
                        let recent = sessions.prefix(3)
                        let older = sessions.dropFirst(3).prefix(3)
                        let recentAvg = averageDuration(recent)
                        let olderAvg = averageDuration(older)
                        let delta = recentAvg - olderAvg
                        insightRow(
                            title: "TENDANCE DE DURÉE",
                            value: delta >= 0 ? "+\(Int(delta)) MIN" : "\(Int(delta)) MIN",
                            note: "Comparaison entre tes \(older.count) sessions précédentes et tes \(recent.count) dernières sessions."
                        )
                    }
                    if count >= 2 {
                        let modeCounts = Dictionary(grouping: sessions, by: \.mode).mapValues(\.count)
                        let top = modeCounts.max { $0.value < $1.value }
                        if let top {
                            insightRow(
                                title: "DISCIPLINE DOMINANTE",
                                value: top.key.frenchLabel,
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

    private func average(scores: [EvaluationResult], matching names: [String]) -> Double? {
        let values = scores.flatMap(\.dimensions)
            .filter { dimension in
                names.contains { dimension.name.uppercased().contains($0) }
            }
            .map(\.score)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
