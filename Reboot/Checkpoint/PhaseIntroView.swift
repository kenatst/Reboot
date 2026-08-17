import SwiftUI

/// Cinematic introduction when entering phases 02–04.
struct PhaseIntroView: View {
    let phase: Int
    var onContinue: () -> Void

    @State private var visible = false

    private var intro: PhaseIntro? {
        ContentStore.phaseIntro(phase: phase)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            RBRadialField(color: .signalCyan, opacity: 0.07, diameter: 360)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.36)

            VStack(spacing: 0) {
                Spacer()
                RBStatusChip(text: "PHASE \(String(format: "%02d", phase))", color: .signalCyan, pulse: true)
                Text(intro?.title ?? "")
                    .font(.heroBlack(size: 44))
                    .tracking(-0.6)
                    .foregroundStyle(.signalCyan)
                    .padding(.top, 22)
                if let lines = intro?.lines {
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.heroBlack(size: 28))
                            .foregroundStyle(.bone)
                            .multilineTextAlignment(.center)
                            .lineSpacing(-2)
                            .padding(.top, 14)
                    }
                }
                if let body = intro?.body {
                    Text(body)
                        .font(.body(size: 15))
                        .foregroundStyle(.softBone)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 24)
                        .padding(.horizontal, 28)
                }
                Spacer()
                Button {
                    onContinue()
                } label: {
                    HStack {
                        Text("ENTRER DANS LA PHASE")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.rbSystem)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
        }
        .onAppear {
            withAnimation(.easeOut(duration: RBMotion.hero)) {
                visible = true
            }
        }
    }
}
