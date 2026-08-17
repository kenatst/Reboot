import SwiftUI

/// ONBOARDING 05 — THE CONTRACT
/// Nearly full VOID. One commitment.
struct OnboardingContractView: View {
    var commit: () -> Void
    var skip: () -> Void = {}

    @State private var visible = false
    @State private var lockPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 730
            ZStack {
                Color.void.ignoresSafeArea()

                // Activation artwork: small, centered, restrained.
                OnboardingArt.render(OnboardingArt.activation, contentMode: .fit, opacity: 0.85)
                    .frame(width: compact ? 190 : 230, height: compact ? 190 : 230)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * (compact ? 0.16 : 0.19))
                    .opacity(visible ? 1 : 0)
                    .scaleEffect(visible ? 1 : 0.96)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    HStack {
                        RBStatusChip(text: "REBOOT / READY", color: .signalCyan, pulse: true)
                        Spacer()
                        RBDayCounter(day: 1)
                    }
                    .padding(.bottom, 20)

                    RBHeroStatement(
                        text: "REPRENDS\nTON\nATTENTION.",
                        size: compact ? 40 : 50
                    )

                    Text("5–25 minutes par jour.\nPas de streak à protéger. Pas de pièces. Pas de classement. Pas de culpabilité.")
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(4)
                        .padding(.top, 20)

                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.line)
                            .frame(width: 3, height: 26)
                        Text("Si tu rates un jour :\nTU REPRENDS.")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundStyle(.bone)
                            .lineSpacing(2)
                    }
                    .padding(.top, 18)

                    Text("Le programme avance quand tu t'entraînes, pas quand le calendrier avance.")
                        .font(.metadata(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(.ash)
                        .padding(.top, 12)

                    Button(action: {
                        withAnimation(.easeOut(duration: RBMotion.duration(0.3, reduceMotion: reduceMotion))) {
                            lockPulse = true
                        }
                        commit()
                    }) {
                        HStack {
                            RBSignalPulse(color: .signalCyan, diameter: 7, active: lockPulse)
                            Text("BEGIN REBOOT")
                                .padding(.leading, 4)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 26)

                    Button(action: skip) {
                        Text("PAS MAINTENANT")
                            .font(.metadata(size: 11))
                            .tracking(2)
                            .foregroundStyle(.ash)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, max(18, geo.safeAreaInsets.bottom + 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 16)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: RBMotion.duration(0.5, reduceMotion: reduceMotion))) {
                visible = true
            }
        }
    }
}
