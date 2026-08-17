import SwiftUI

/// ONBOARDING 03 — THE CONTRAST
/// Residual red noise exits; the structure settles; one cyan signal travels.
struct OnboardingContrastView: View {
    var advance: () -> Void

    @State private var noiseLeaving = false
    @State private var settled = false
    @State private var signalTravel = false
    @State private var contentVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let residualWords = ["NOISE", "ALERT", "PING", "SWIPE"]

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 730
            ZStack(alignment: .bottom) {
                Color.void.ignoresSafeArea()

                // ART: restored head, generous and stable.
                OnboardingArt.render(OnboardingArt.recovery, contentMode: .fill, opacity: 0.96)
                    .frame(width: geo.size.width, height: compact ? geo.size.height * 0.62 : geo.size.height * 0.66)
                    .clipped()
                    .offset(y: compact ? -geo.size.height * 0.18 : -geo.size.height * 0.14)
                    .scaleEffect(settled ? 1.0 : 1.05)
                    .animation(.easeOut(duration: RBMotion.duration(0.9, reduceMotion: reduceMotion)), value: settled)

                // Residual noise exits progressively.
                RBNoiseField(words: residualWords, active: !noiseLeaving, tint: .signalRed)
                    .frame(height: geo.size.height * 0.5)
                    .offset(y: -geo.size.height * 0.16)
                    .opacity(noiseLeaving ? 0 : 0.85)
                    .scaleEffect(noiseLeaving ? 1.15 : 1)
                    .animation(.easeInOut(duration: RBMotion.duration(1.0, reduceMotion: reduceMotion)), value: noiseLeaving)

                // Single cyan signal crossing the structure.
                RBSignalLine(color: .signalCyan, thickness: 2, draws: signalTravel)
                    .frame(width: compact ? geo.size.width * 0.7 : geo.size.width * 0.76)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * (compact ? 0.26 : 0.30))
                    .opacity(settled ? 1 : 0)

                if settled {
                    RBDiagnosticTag(label: "SIGNAL", value: "STABLE", valueColor: .signalCyan, alignment: .leading)
                        .position(x: geo.size.width * 0.24, y: geo.size.height * (compact ? 0.15 : 0.17))
                    RBDiagnosticTag(label: "INPUT", value: "CHOISI", valueColor: .signalCyan, alignment: .trailing)
                        .position(x: geo.size.width * 0.76, y: geo.size.height * (compact ? 0.22 : 0.25))
                    RBDiagnosticTag(label: "ATTENTION", value: "DIRIGÉE", valueColor: .signalCyan, alignment: .leading)
                        .position(x: geo.size.width * 0.25, y: geo.size.height * (compact ? 0.32 : 0.36))
                    RBDiagnosticTag(label: "ESPACE", value: "RETROUVÉ", valueColor: .signalCyan, alignment: .trailing)
                        .position(x: geo.size.width * 0.75, y: geo.size.height * (compact ? 0.40 : 0.45))
                }

                RBArtScrim()
                    .frame(height: compact ? geo.size.height * 0.58 : geo.size.height * 0.62)
                    .offset(y: compact ? geo.size.height * 0.19 : geo.size.height * 0.18)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    RBSystemLabel(text: "REBOOT / SIGNAL", color: .signalCyan)
                        .padding(.bottom, 14)

                    RBHeroStatement(
                        text: "MAINTENANT,\nENLÈVE\nLE BRUIT.",
                        size: compact ? 38 : 46
                    )
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 14)

                    Text("Pas de magie. Moins de changements. Plus de temps avec une seule chose. Plus de place pour comprendre.")
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(3)
                        .padding(.top, 18)

                    Button(action: advance) {
                        HStack {
                            Text("REPRENDRE LE SIGNAL")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 26)
                    .opacity(contentVisible ? 1 : 0)
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, max(18, geo.safeAreaInsets.bottom + 12))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            runRecovery()
        }
    }

    private func runRecovery() {
        let initial = RBMotion.duration(0.35, reduceMotion: reduceMotion)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(initial * 1_000_000_000))
            withAnimation(.easeInOut(duration: RBMotion.duration(0.8, reduceMotion: reduceMotion))) {
                noiseLeaving = true
            }
            try? await Task.sleep(nanoseconds: UInt64(RBMotion.duration(0.9, reduceMotion: reduceMotion) * 1_000_000_000))
            withAnimation(.easeOut(duration: RBMotion.duration(0.6, reduceMotion: reduceMotion))) {
                settled = true
                signalTravel = true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation(.easeOut(duration: 0.45)) {
                contentVisible = true
            }
        }
    }
}
