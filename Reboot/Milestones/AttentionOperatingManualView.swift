import SwiftUI
import SwiftData

/// REBOOT V3 — Day 90 Attention Operating Manual View
/// A personal, actionable operating manual generated from 90 days of measured evidence.
struct AttentionOperatingManualView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var manual: AttentionOperatingManualEngine.OperatingManual?
    @State private var selectedSection: AttentionOperatingManualEngine.ManualSection?

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if let manual = manual {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            RBStatusChip(text: "REBOOT / JOUR 090", color: .signalCyan, pulse: false)
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.ash)
                            }
                        }
                        .padding(.top, 24)

                        Text("MANUEL OPÉRATOIRE\nDE TON ATTENTION.")
                            .font(.heroBlack(size: 34))
                            .tracking(-0.4)
                            .foregroundStyle(.bone)
                            .padding(.top, 16)

                        Text("Ce document n'est pas un trophée. C'est la synthèse rigoureuse de tes 90 jours : ce qui brise ton attention, ce qui la protège, et les règles mesurées qui fonctionnent chez toi.")
                            .font(.body(size: 14))
                            .foregroundStyle(.softBone)
                            .lineSpacing(5)
                            .padding(.top, 12)

                        HStack(spacing: 12) {
                            statCard(label: "SESSIONS", value: "\(manual.totalSessionsCount)")
                            statCard(label: "FLOW LAB", value: "\(manual.totalFlowCount)")
                            statCard(label: "RÈGLES ACTIVES", value: "\(manual.activeRulesCount)")
                        }
                        .padding(.top, 20)

                        Text("SEIZE DIMENSIONS MESURÉES")
                            .font(.metadata(size: 10))
                            .tracking(2)
                            .foregroundStyle(.ash)
                            .padding(.top, 34)

                        VStack(spacing: 14) {
                            ForEach(manual.sections) { section in
                                sectionCard(section)
                            }
                        }
                        .padding(.top, 14)

                        // Core Mode Box
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MODE DE CROISIÈRE POST-JOUR 90")
                                .font(.metadata(size: 10))
                                .tracking(1.8)
                                .foregroundStyle(.signalCyan)
                            Text(manual.coreMaintenanceMode)
                                .font(.system(size: 15, weight: .bold, design: .default))
                                .foregroundStyle(.bone)
                            Text("REBOOT bascule désormais en mode maintenance : 3 blocs de travail profond protégés par semaine et une revue d'alignement.")
                                .font(.body(size: 13))
                                .foregroundStyle(.ash)
                                .lineSpacing(3)
                        }
                        .padding(18)
                        .background(Color.graphiteSurface)
                        .clipShape(RBChamferedShape(cut: 16))
                        .overlay(RBChamferedShape(cut: 16).stroke(Color.signalCyan.opacity(0.4), lineWidth: 1))
                        .padding(.top, 30)

                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Text("ENTRER EN MODE CROISIÈRE")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                        .buttonStyle(.rbSystem)
                        .padding(.top, 26)
                        .padding(.bottom, 44)
                    }
                    .padding(.horizontal, RBSpacing.screen)
                }
            } else {
                ProgressView()
                    .tint(.signalCyan)
            }
        }
        .onAppear {
            manual = AttentionOperatingManualEngine.generate(context: modelContext)
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.metadata(size: 9))
                .tracking(1.4)
                .foregroundStyle(.ash)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.bone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.deepCarbon)
        .clipShape(RBChamferedShape(cut: 10))
    }

    private func sectionCard(_ section: AttentionOperatingManualEngine.ManualSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(section.number)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.signalCyan)
                Text(section.title)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(.bone)
                Spacer()
                confidenceBadge(section.confidence)
            }

            Text(section.finding)
                .font(.body(size: 13))
                .foregroundStyle(.softBone)
                .lineSpacing(3)

            if let rule = section.practicalRule {
                HStack(alignment: .top, spacing: 8) {
                    Rectangle()
                        .fill(Color.signalCyan)
                        .frame(width: 2, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TA RÈGLE OPÉRATOIRE")
                            .font(.metadata(size: 8))
                            .tracking(1.4)
                            .foregroundStyle(.signalCyan)
                        Text(rule)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.bone)
                    }
                }
                .padding(.top, 4)
            }

            if let rec = section.recommendation {
                Text("CONSEIL : \(rec)")
                    .font(.metadata(size: 9))
                    .tracking(1.1)
                    .foregroundStyle(.ash)
                    .padding(.top, 2)
            }

            HStack {
                Text(section.evidenceSummary)
                    .font(.metadata(size: 8))
                    .foregroundStyle(.ash.opacity(0.8))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.deepCarbon)
        .clipShape(RBChamferedShape(cut: 12))
    }

    private func confidenceBadge(_ conf: AttentionOperatingManualEngine.Confidence) -> some View {
        let color: Color = {
            switch conf {
            case .strong: return .signalCyan
            case .early: return .acid
            case .selfReport: return .ash
            case .unknown: return .line
            }
        }()

        return Text(conf.rawValue)
            .font(.metadata(size: 8))
            .tracking(1.2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
