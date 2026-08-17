import SwiftUI

/// ONBOARDING 02 — THE DIAGNOSTIC
/// Transparent head artwork with a slow scan and red fragments entering.
struct OnboardingDiagnosticView: View {
    var advance: () -> Void

    @State private var fragmentsTrigger = false
    @State private var labelsVisible = false
    @State private var contentVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 730
            ZStack(alignment: .bottom) {
                Color.void.ignoresSafeArea()

                OnboardingArt.render(OnboardingArt.diagnostic, contentMode: .fill, opacity: 0.92)
                    .frame(width: geo.size.width, height: compact ? geo.size.height * 0.56 : geo.size.height * 0.60)
                    .clipped()
                    .offset(y: compact ? -geo.size.height * 0.14 : -geo.size.height * 0.10)

                RBScanLine(color: .signalRed.opacity(0.45))
                    .frame(height: compact ? geo.size.height * 0.42 : geo.size.height * 0.48)
                    .offset(y: compact ? -geo.size.height * 0.05 : -geo.size.height * 0.02)

                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.signalRed.opacity(0.75))
                            .frame(width: 4 + CGFloat((index * 3) % 5), height: 2 + CGFloat(index % 3))
                            .offset(
                                x: fragmentsTrigger ? horizontalOffset(index) : 0,
                                y: verticalOffset(index)
                            )
                            .animation(
                                .easeInOut(duration: RBMotion.duration(1.0, reduceMotion: reduceMotion))
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.13),
                                value: fragmentsTrigger
                            )
                    }
                }
                .frame(height: compact ? geo.size.height * 0.5 : geo.size.height * 0.56)
                .allowsHitTesting(false)
                .opacity(labelsVisible ? 0.15 : 1)

                if labelsVisible {
                    RBDiagnosticTag(label: "SIGNAL", value: "FRAGMENTÉ", valueColor: .signalRed, alignment: .leading)
                        .position(x: geo.size.width * 0.24, y: geo.size.height * (compact ? 0.16 : 0.18))
                    RBDiagnosticTag(label: "CHARGE", value: "ÉLEVÉE", valueColor: .signalRed, alignment: .trailing)
                        .position(x: geo.size.width * 0.76, y: geo.size.height * (compact ? 0.24 : 0.27))
                    RBDiagnosticTag(label: "SWITCHING", value: "FRÉQUENT", valueColor: .signalRed, alignment: .leading)
                        .position(x: geo.size.width * 0.25, y: geo.size.height * (compact ? 0.34 : 0.38))
                    RBDiagnosticTag(label: "PROFONDEUR", value: "FAIBLE", valueColor: .signalRed, alignment: .trailing)
                        .position(x: geo.size.width * 0.75, y: geo.size.height * (compact ? 0.42 : 0.47))
                }

                RBArtScrim()
                    .frame(height: compact ? geo.size.height * 0.56 : geo.size.height * 0.62)
                    .offset(y: compact ? geo.size.height * 0.20 : geo.size.height * 0.19)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    RBSystemLabel(text: "REBOOT / DIAGNOSTIC", color: .signalRed)
                        .padding(.bottom, 14)

                    RBHeroStatement(
                        text: "CECI EST\nTON ATTENTION\nSOUS BRUIT.",
                        size: compact ? 36 : 44
                    )
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 14)

                    Text("Quand chaque seconde peut apporter un nouveau stimulus, rester avec une seule chose demande davantage d'effort.")
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(3)
                        .padding(.top, 18)

                    Text("ILLUSTRATION DU MODÈLE")
                        .font(.metadata(size: 9))
                        .tracking(1.6)
                        .foregroundStyle(.ash.opacity(0.8))
                        .padding(.top, 10)

                    Button(action: advance) {
                        HStack {
                            Text("COUPER LE BRUIT")
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
            fragmentsTrigger = true
            let delay = RBMotion.duration(0.5, reduceMotion: reduceMotion)
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                withAnimation(.easeOut(duration: RBMotion.duration(0.5, reduceMotion: reduceMotion))) {
                    labelsVisible = true
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeOut(duration: 0.45)) {
                    contentVisible = true
                }
            }
        }
    }

    private func horizontalOffset(_ index: Int) -> CGFloat {
        index.isMultiple(of: 2)
            ? -150 - CGFloat(index * 9)
            : 150 + CGFloat(index * 11)
    }

    private func verticalOffset(_ index: Int) -> CGFloat {
        CGFloat((index * 23) % 120 - 60)
    }
}
