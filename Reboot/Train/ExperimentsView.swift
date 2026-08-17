import SwiftUI
import SwiftData

/// EXPERIMENT ENGINE — test hypotheses on your own behavior.
struct ExperimentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BehaviorExperiment.startedAt, order: .reverse) private var experiments: [BehaviorExperiment]
    @Query(sort: \ExperimentObservation.timestamp, order: .reverse) private var observations: [ExperimentObservation]

    @State private var showTemplates = false

    private var activeList: [BehaviorExperiment] {
        experiments.filter { $0.status == "BASELINE" || $0.status == "RUNNING" || $0.status == "READY_TO_REVIEW" || $0.status == "PROPOSED" }
    }

    private var historicalList: [BehaviorExperiment] {
        experiments.filter { $0.status == "COMPLETED" || $0.status == "ABANDONED" }
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        RBSystemLabel(text: "REBOOT / EXPERIMENTS", color: .acid)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.ash)
                        }
                    }
                    .padding(.top, 18)

                    Text("TESTE UNE\nHYPOTHÈSE SUR TOI.")
                        .font(.heroBlack(size: 36))
                        .tracking(-0.4)
                        .foregroundStyle(.bone)
                        .padding(.top, 18)

                    Button {
                        showTemplates = true
                    } label: {
                        HStack {
                            Text("NOUVELLE EXPÉRIENCE")
                                .font(.metadata(size: 10))
                                .tracking(2)
                                .foregroundStyle(.acid)
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundStyle(.acid)
                        }
                        .padding(16)
                        .background(Color.deepCarbon)
                        .clipShape(RBChamferedShape(cut: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)

                    if !activeList.isEmpty {
                        Text("EXPÉRIENCES EN COURS")
                            .font(.metadata(size: 10))
                            .tracking(2)
                            .foregroundStyle(.ash)
                            .padding(.top, 28)
                        ForEach(activeList) { experiment in
                            experimentLifecycleCard(experiment)
                                .padding(.top, 12)
                        }
                    } else {
                        Text("Aucune expérience active. Chaque expérience teste une condition sur trois sessions comparables, et la conclusion reste provisoire.")
                            .font(.body(size: 14))
                            .foregroundStyle(.ash)
                            .lineSpacing(4)
                            .padding(.top, 24)
                    }

                    if !historicalList.isEmpty {
                        Text("HISTORIQUE")
                            .font(.metadata(size: 10))
                            .tracking(2)
                            .foregroundStyle(.ash)
                            .padding(.top, 36)
                        ForEach(historicalList) { experiment in
                            historyCard(experiment)
                                .padding(.top, 10)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .sheet(isPresented: $showTemplates) {
            TemplatesView()
        }
    }

    private func experimentLifecycleCard(_ experiment: BehaviorExperiment) -> some View {
        let expObs = observations.filter { $0.experimentID == experiment.id }
        let baseCount = expObs.filter { $0.condition == "BASELINE" }.count
        let testCount = expObs.filter { $0.condition == "TEST" }.count
        let comparison = SessionComparator.compare(observations: expObs)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(experiment.title)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundStyle(.bone)
                Spacer()
                statusBadge(experiment.status, baseCount: baseCount, testCount: testCount)
            }

            Text(experiment.hypothesis)
                .font(.body(size: 13))
                .foregroundStyle(.softBone)
                .lineSpacing(3)

            Text("MESURE : \(experiment.metric.uppercased())")
                .font(.metadata(size: 9))
                .tracking(1.4)
                .foregroundStyle(.acid)

            if experiment.status == "BASELINE" || experiment.status == "PROPOSED" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("LIGNE DE BASE : \(baseCount) / 3 SESSIONS")
                            .font(.metadata(size: 9))
                            .foregroundStyle(.ash)
                        Spacer()
                    }
                    ProgressView(value: min(1.0, Double(baseCount) / 3.0))
                        .tint(Color.acid)
                }
                .padding(.top, 4)
            } else if experiment.status == "RUNNING" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("CONDITION TEST : \(testCount) / 3 SESSIONS")
                            .font(.metadata(size: 9))
                            .foregroundStyle(.signalCyan)
                        Spacer()
                    }
                    ProgressView(value: min(1.0, Double(testCount) / 3.0))
                        .tint(Color.signalCyan)
                }
                .padding(.top, 4)
            } else if experiment.status == "READY_TO_REVIEW" {
                reviewBlock(experiment: experiment, comparison: comparison)
            }
        }
        .padding(16)
        .background(Color.graphiteSurface)
        .clipShape(RBChamferedShape(cut: 12))
    }

    private func reviewBlock(experiment: BehaviorExperiment, comparison: SessionComparator.ComparisonResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.line)
                .frame(height: 1)
                .padding(.vertical, 4)

            Text("RÉSULTATS DE L'OBSERVATION")
                .font(.metadata(size: 9))
                .tracking(1.4)
                .foregroundStyle(.acid)

            Text(comparison.summaryNote)
                .font(.body(size: 13))
                .foregroundStyle(.bone)
                .lineSpacing(3)

            HStack(spacing: 10) {
                Button {
                    AdaptiveRebootEngineDriver.promoteToRule(
                        title: experiment.title,
                        source: "Expérience validée : \(experiment.title)",
                        context: modelContext
                    )
                    experiment.status = "COMPLETED"
                    experiment.result = "kept"
                    experiment.completedAt = .now
                    try? modelContext.save()
                } label: {
                    Text("GARDER COMME RÈGLE")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.bonePlate)
                        .clipShape(RBChamferedShape(cut: 8))
                }
                .buttonStyle(.plain)

                Button {
                    experiment.status = "RUNNING"
                    try? modelContext.save()
                } label: {
                    Text("TESTER PLUS")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.softBone)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(Rectangle().stroke(Color.line, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    experiment.status = "ABANDONED"
                    experiment.result = "dropped"
                    experiment.completedAt = .now
                    try? modelContext.save()
                } label: {
                    Text("ABANDONNER")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.signalRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(Rectangle().stroke(Color.signalRed.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
    }

    private func historyCard(_ experiment: BehaviorExperiment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(experiment.title)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(.bone)
                Text(experiment.result == "kept" ? "Conservé comme règle personnelle" : "Non retenu")
                    .font(.body(size: 12))
                    .foregroundStyle(.ash)
            }
            Spacer()
            Text(experiment.result == "kept" ? "CONSERVÉ" : "ABANDONNÉ")
                .font(.metadata(size: 8))
                .tracking(1.2)
                .foregroundStyle(experiment.result == "kept" ? .acid : .ash)
        }
        .padding(12)
        .background(Color.deepCarbon)
        .clipShape(RBChamferedShape(cut: 8))
    }

    private func statusBadge(_ status: String, baseCount: Int, testCount: Int) -> some View {
        let text: String
        let color: Color
        switch status {
        case "BASELINE", "PROPOSED":
            text = "BASELINE \(baseCount)/3"
            color = .acid
        case "RUNNING":
            text = "TEST \(testCount)/3"
            color = .signalCyan
        case "READY_TO_REVIEW":
            text = "PRÊT À REVOIR"
            color = .bone
        case "COMPLETED":
            text = "CONSERVÉ"
            color = .acid
        case "ABANDONED":
            text = "ABANDONNÉ"
            color = .signalRed
        default:
            text = status
            color = .ash
        }

        return Text(text)
            .font(.metadata(size: 8))
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("CHOISIS UNE EXPÉRIENCE")
                        .font(.heroBlack(size: 28))
                        .foregroundStyle(.bone)
                        .padding(.top, 30)
                    ForEach(ContentStore.experimentTemplates) { template in
                        Button {
                            AdaptiveRebootEngineDriver.startExperiment(template: template, context: modelContext)
                            dismiss()
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(template.title)
                                        .font(.system(size: 14, weight: .bold, design: .default))
                                        .foregroundStyle(.bone)
                                    Text(template.hypothesis)
                                        .font(.body(size: 12))
                                        .foregroundStyle(.ash)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.acid)
                            }
                            .padding(12)
                            .background(Color.deepCarbon)
                            .clipShape(RBChamferedShape(cut: 10))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
    }
}
