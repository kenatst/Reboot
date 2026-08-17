import SwiftUI
import SwiftData

/// 90 DAYS. ONE SYSTEM. Dedicated full protocol curriculum browser.
struct ProgramView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var progressList: [RebootProgress]
    @Query private var completions: [ProtocolDayCompletion]
    @State private var selectedPhase = 1
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

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 14)

                    heroSection
                        .padding(.top, 28)

                    phasesSelector
                        .padding(.top, 32)

                    phaseDetail(phaseNumber: selectedPhase)
                        .padding(.top, 24)

                    RBEditorialDivider(label: "CURRICULUM / PHASE 0\(selectedPhase)")
                        .padding(.top, 32)

                    daysList(phaseNumber: selectedPhase)
                        .padding(.top, 20)
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

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("90 JOURS.\nUN SEUL SYSTÈME.")
                .font(.heroBlack(size: 38))
                .tracking(-0.5)
                .foregroundStyle(.bone)
                .lineSpacing(-4)

            Text("Le protocole avance quand tu t'entraînes. Aucun jour n'est ignoré.")
                .font(.body(size: 15))
                .foregroundStyle(.softBone)
                .lineSpacing(3)
                .padding(.top, 8)
        }
    }

    private var phasesSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHASES")
                .font(.metadata(size: 10))
                .tracking(2)
                .foregroundStyle(.ash)

            VStack(spacing: 8) {
                ForEach(ProtocolCurriculum.phases) { phase in
                    let isSelected = selectedPhase == phase.number
                    let isCurrent = phase.range.contains(currentDay)
                    let isUnlocked = currentDay >= phase.range.lowerBound

                    Button {
                        RBHaptics.play(.selection)
                        withAnimation(RBMotion.fastAnim) {
                            selectedPhase = phase.number
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(isCurrent ? Color.signalCyan : (isUnlocked ? Color.bone : Color.ash.opacity(0.4)))
                                .frame(width: 6, height: 6)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text("PHASE \(String(format: "%02d", phase.number))")
                                        .font(.metadata(size: 10))
                                        .tracking(1.4)
                                        .foregroundStyle(isCurrent ? Color.signalCyan : Color.ash)
                                    Text("JOURS \(String(format: "%02d", phase.range.lowerBound))–\(String(format: "%02d", phase.range.upperBound))")
                                        .font(.metadata(size: 9))
                                        .foregroundStyle(.ash.opacity(0.6))
                                }
                                Text(phase.title)
                                    .font(.system(size: 15, weight: .bold, design: .default))
                                    .foregroundStyle(isSelected ? Color.bone : Color.softBone)
                            }

                            Spacer()

                            if isCurrent {
                                RBStatusChip(text: "EN COURS", color: .signalCyan, pulse: false)
                            } else if isUnlocked {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.ash.opacity(0.8))
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(isSelected ? Color.graphite.opacity(0.8) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: RBRadius.sm)
                                .stroke(isSelected ? Color.line.opacity(0.9) : Color.line.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func phaseDetail(phaseNumber: Int) -> some View {
        let phase = ProtocolCurriculum.phase(forPhase: phaseNumber)
        return VStack(alignment: .leading, spacing: 10) {
            Text("OBJECTIF DE LA PHASE")
                .font(.metadata(size: 10))
                .tracking(2)
                .foregroundStyle(.ash)

            Text(phaseDescription(phaseNumber))
                .font(.body(size: 14))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line.opacity(0.7), lineWidth: 1)
        )
    }

    private func phaseDescription(_ phase: Int) -> String {
        switch phase {
        case 1:
            return "Couper le réflexe de vérification automatique. Tolérer 5 à 15 minutes de travail ininterrompu et réapprendre à fermer les stimuli concurrents."
        case 2:
            return "Stabiliser l'attention continue sur 15 à 30 minutes. Renforcer la mémoire de travail par des restitutions actives et régulières."
        case 3:
            return "Approfondir l'endurance cognitive jusqu'à 45 minutes. Développer des reconstructions complexes et la clarté d'enseignement."
        default:
            return "Reprendre le contrôle souverain de ton temps. Transférer la maîtrise attentionnelle dans tes activités complexes sans assistance."
        }
    }

    private func daysList(phaseNumber: Int) -> some View {
        let phase = ProtocolCurriculum.phase(forPhase: phaseNumber)
        let phaseDays = (phase.range.lowerBound...phase.range.upperBound).map { ProtocolCurriculum.day($0) }

        return VStack(spacing: 8) {
            ForEach(phaseDays) { day in
                let isDone = completedDayNumbers.contains(day.dayNumber)
                let isCurrent = day.dayNumber == currentDay
                let isFuture = day.dayNumber > currentDay

                Button {
                    if isCurrent {
                        activeRequest = SessionRequestFactory.today(day: day.dayNumber)
                    } else if !isFuture {
                        activeRequest = SessionRequestFactory.today(day: day.dayNumber)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: "%03d", day.dayNumber))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(isCurrent ? .signalCyan : (isDone ? .bone : .ash.opacity(0.5)))
                            
                            if isDone {
                                Circle()
                                    .fill(Color.signalCyan)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 38, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(day.mode.label)
                                    .font(.metadata(size: 10))
                                    .tracking(1.4)
                                    .foregroundStyle(isCurrent ? .signalCyan : (isDone ? .bone : .ash))
                                
                                Text("\(day.recommendedDuration) MIN")
                                    .font(.metadata(size: 9))
                                    .foregroundStyle(.ash.opacity(0.7))

                                Spacer()

                                if isDone {
                                    Text("FAIT")
                                        .font(.metadata(size: 9))
                                        .tracking(1)
                                        .foregroundStyle(.signalCyan)
                                } else if isCurrent {
                                    Text("AUJOURD'HUI")
                                        .font(.metadata(size: 9))
                                        .tracking(1)
                                        .foregroundStyle(.signalCyan)
                                }
                            }

                            Text(day.intention)
                                .font(.body(size: 13))
                                .foregroundStyle(isFuture ? .ash.opacity(0.5) : .softBone)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(isCurrent ? Color.graphite.opacity(0.6) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: RBRadius.sm)
                            .stroke(isCurrent ? Color.signalCyan.opacity(0.6) : Color.line.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
