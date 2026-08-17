import SwiftUI

/// ONBOARDING 04 — THE PROTOCOL
/// The 90-day timeline draws itself; noise visibly decreases per phase.
struct OnboardingProtocolView: View {
    var advance: () -> Void

    @State private var timelineVisible = true
    @State private var contentVisible = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 730
            ZStack(alignment: .bottom) {
                Color.void.ignoresSafeArea()

                OnboardingArt.render(OnboardingArt.protocolArt, contentMode: .fill, opacity: compact ? 0.22 : 0.3)
                    .frame(width: geo.size.width, height: geo.size.height * 0.55)
                    .clipped()
                    .offset(y: -geo.size.height * 0.18)

                RBArtScrim()
                    .frame(height: geo.size.height * 0.6)
                    .offset(y: geo.size.height * 0.16)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    RBSystemLabel(text: "THE REBOOT PROTOCOL", color: .signalCyan)
                        .padding(.bottom, 10)

                    RBHeroStatement(
                        text: "90 DAYS.",
                        size: compact ? 44 : 54
                    )

                    Text("PAS POUR\nDEVENIR PARFAIT.\nPOUR RÉAPPRENDRE À RESTER.")
                        .font(.system(size: 15, weight: .bold, design: .default))
                        .foregroundStyle(.softBone)
                        .lineSpacing(3)
                        .padding(.top, 10)

                    // Timeline draws itself.
                    VStack(spacing: 0) {
                        ForEach(ProtocolCurriculum.phases) { phase in
                            HStack(spacing: 14) {
                                Circle()
                                    .stroke(phase.number <= 2 ? Color.signalRed : Color.signalCyan, lineWidth: 1.5)
                                    .frame(width: 10, height: 10)
                                Text(String(format: "%02d", phase.number))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(phase.number <= 2 ? .signalRed : .signalCyan)
                                    .frame(width: 22, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(phase.title)
                                        .font(.system(size: 14, weight: .bold, design: .default))
                                        .foregroundStyle(.softBone)
                                    Text("JOURS \(String(format: "%02d", phase.range.lowerBound))–\(String(format: "%02d", phase.range.upperBound)) — \(phase.subtitle)")
                                        .font(.metadata(size: 9))
                                        .foregroundStyle(.ash)
                                }
                                Spacer()
                                noiseMeter(phase.number)
                            }
                            .padding(.vertical, 8)
                            if phase.number < 4 {
                                Rectangle()
                                    .fill(Color.line.opacity(0.7))
                                    .frame(height: 1)
                                    .padding(.leading, 32)
                            }
                        }
                    }
                    .padding(.top, 18)

                    Text("90 jours est la durée du programme REBOOT, pas une durée biologique universelle.")
                        .font(.metadata(size: 9))
                        .tracking(0.8)
                        .foregroundStyle(.ash.opacity(0.75))
                        .padding(.top, 12)

                    Button(action: advance) {
                        HStack {
                            Text("VOIR L'ENTRAÎNEMENT")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 22)
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, max(16, geo.safeAreaInsets.bottom + 10))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func noiseMeter(_ phaseNumber: Int) -> some View {
        let reds = [3, 2, 1, 0][phaseNumber - 1]
        let cyans = [0, 0, 1, 2][phaseNumber - 1]
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        index < reds ? Color.signalRed
                            : index < reds + cyans ? Color.signalCyan
                            : Color.line
                    )
                    .frame(width: 4, height: 4)
            }
        }
    }
}
