import SwiftUI

/// ONBOARDING 01 — THE ATTACK
/// Art begins relatively quiet, noise builds, then everything freezes.
struct OnboardingAttackView: View {
    var advance: () -> Void

    @State private var noiseActive = false
    @State private var noiseFrozen = false
    @State private var heroVisible = false
    @State private var adaptLineVisible = false
    @State private var ctaVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let noiseWords = ["CHECK", "NEXT", "NEW", "OPEN", "SWIPE", "NOW", "LIVE", "MORE"]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.void.ignoresSafeArea()

                OnboardingArt.render(OnboardingArt.overload, contentMode: .fill, opacity: 0.95)
                    .frame(width: geo.size.width, height: geo.size.height * 0.66)
                    .clipped()
                    .offset(y: -geo.size.height * 0.16)
                    .scaleEffect(noiseFrozen ? 1.02 : 1)
                    .opacity(noiseFrozen ? 0.92 : 1)
                    .animation(
                        .easeInOut(duration: RBMotion.duration(0.4, reduceMotion: reduceMotion)),
                        value: noiseFrozen
                    )

                RBNoiseField(words: noiseWords, active: noiseActive && !noiseFrozen, tint: .signalRed)
                    .frame(height: geo.size.height * 0.62)
                    .offset(y: -geo.size.height * 0.18)
                    .opacity(noiseFrozen ? 0.18 : 1)
                    .animation(.easeInOut(duration: 0.45), value: noiseFrozen)

                RBArtScrim()
                    .frame(height: geo.size.height * 0.62)
                    .offset(y: geo.size.height * 0.19)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        RBSystemLabel(text: "REBOOT / WAKE UP", color: .signalRed)
                        if noiseFrozen {
                            RBSignalPulse(color: .signalRed, diameter: 6, active: true)
                        }
                    }
                    .padding(.bottom, 14)

                    RBHeroStatement(
                        text: "TON ATTENTION\nEST SOUS\nATTAQUE.",
                        size: geo.size.height < 730 ? 40 : 46
                    )
                    .opacity(heroVisible ? 1 : 0)
                    .offset(y: heroVisible ? 0 : 18)
                    .animation(
                        .easeOut(duration: RBMotion.duration(0.4, reduceMotion: reduceMotion)),
                        value: heroVisible
                    )

                    if adaptLineVisible {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.signalRed)
                                .frame(width: 3, height: 18)
                            Text("ET TON CERVEAU\nS'ADAPTE.")
                                .font(.system(size: 15, weight: .bold, design: .default))
                                .foregroundStyle(.signalRed)
                                .lineSpacing(2)
                        }
                        .padding(.top, 18)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }

                    Text("Tu ouvres. Tu scrolles. Tu vérifies. Tu changes. Tu recommences.")
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(3)
                        .padding(.top, 22)

                    Text("Le problème n'est pas que tu ne peux plus te concentrer. Tu t'entraînes toute la journée à changer.")
                        .font(.body(size: 14))
                        .foregroundStyle(.ash)
                        .lineSpacing(3)
                        .padding(.top, 12)

                    if ctaVisible {
                        Button(action: advance) {
                            HStack {
                                Text("VOIR CE QUI SE PASSE")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                        .buttonStyle(.rbPrimary())
                        .padding(.top, 28)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, max(18, geo.safeAreaInsets.bottom + 12))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            runTimeline()
        }
    }

    private func runTimeline() {
        let stage1 = RBMotion.duration(0.55, reduceMotion: reduceMotion)
        let stage2 = RBMotion.duration(1.4, reduceMotion: reduceMotion)
        let stage3 = RBMotion.duration(0.7, reduceMotion: reduceMotion)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(stage1 * 1_000_000_000))
            withAnimation { noiseActive = true }
            try? await Task.sleep(nanoseconds: UInt64(stage2 * 1_000_000_000))
            withAnimation(.easeOut(duration: RBMotion.duration(0.4, reduceMotion: reduceMotion))) {
                noiseFrozen = true
                heroVisible = true
            }
            try? await Task.sleep(nanoseconds: UInt64(stage3 * 1_000_000_000))
            withAnimation(.easeOut(duration: 0.3)) {
                adaptLineVisible = true
                ctaVisible = true
            }
        }
    }
}
