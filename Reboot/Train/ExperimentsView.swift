import SwiftUI
import SwiftData

/// EXPERIMENT ENGINE — test hypotheses on your own behavior.
struct ExperimentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var experiments: [BehaviorExperiment]

    @State private var showTemplates = false

    private var active: [BehaviorExperiment] {
        experiments.filter { $0.status == "active" }
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

                    if !active.isEmpty {
                        Text("ACTIVES")
                            .font(.metadata(size: 10))
                            .tracking(2)
                            .foregroundStyle(.ash)
                            .padding(.top, 28)
                        ForEach(active) { experiment in
                            experimentCard(experiment)
                                .padding(.top, 10)
                        }
                    } else {
                        Text("Aucune expérience active. Chaque expérience teste une condition sur trois sessions comparables, et la conclusion reste provisoire.")
                            .font(.body(size: 14))
                            .foregroundStyle(.ash)
                            .lineSpacing(4)
                            .padding(.top, 24)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .sheet(isPresented: $showTemplates) {
            TemplatesView()
        }
        .onAppear {
            #if DEBUG
            if UITestDriver.autoTour || UITestDriver.experimentsAutoTemplates {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showTemplates = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 8_000_000_000)
                    if let first = experiments.first(where: { $0.status == "active" }) {
                        first.status = "completed"
                        first.result = "kept"
                        try? modelContext.save()
                    }
                }
            }
            #endif
        }
    }

    private func experimentCard(_ experiment: BehaviorExperiment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(experiment.title)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(.bone)
            Text(experiment.hypothesis)
                .font(.body(size: 13))
                .foregroundStyle(.softBone)
                .lineSpacing(3)
            Text("MESURE : \(experiment.metric.uppercased())")
                .font(.metadata(size: 9))
                .tracking(1.4)
                .foregroundStyle(.acid)
            HStack(spacing: 10) {
                Button {
                    experiment.status = "completed"
                    experiment.result = "kept"
                    try? modelContext.save()
                } label: {
                    Text("ÇA MARCHE")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.bonePlate)
                        .clipShape(RBChamferedShape(cut: 8))
                }
                .buttonStyle(.plain)
                Button {
                    experiment.status = "completed"
                    experiment.result = "dropped"
                    try? modelContext.save()
                } label: {
                    Text("À ABANDONNER")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.signalRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(Rectangle().stroke(Color.signalRed.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button {
                    experiment.status = "completed"
                    experiment.result = "inconclusive"
                    try? modelContext.save()
                } label: {
                    Text("PAS CLAIR")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.ash)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(Rectangle().stroke(Color.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.graphiteSurface)
        .clipShape(RBChamferedShape(cut: 12))
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
        .onAppear {
            #if DEBUG
            if UITestDriver.autoTour {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if let first = ContentStore.experimentTemplates.first {
                        AdaptiveRebootEngineDriver.startExperiment(template: first, context: modelContext)
                    }
                    dismiss()
                }
            }
            #endif
        }
    }
}
