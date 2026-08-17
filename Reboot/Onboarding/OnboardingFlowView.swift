import SwiftUI

struct OnboardingFlowView: View {
    var initialPage = 0
    var onFinish: (Bool) -> Void = { _ in }

    @State private var page: Int
    @State private var blackout = false
    @State private var initialized = false

    init(initialPage: Int = 0, onFinish: @escaping (Bool) -> Void = { _ in }) {
        self.initialPage = initialPage
        self.onFinish = onFinish
        self._page = State(initialValue: initialPage)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingAttackView(advance: advance)
                    .tag(0)
                OnboardingDiagnosticView(advance: advance)
                    .tag(1)
                OnboardingContrastView(advance: advance)
                    .tag(2)
                OnboardingProtocolView(advance: advance)
                    .tag(3)
                OnboardingContractView(commit: commit, skip: { onFinish(false) })
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.28), value: page)

            VStack {
                HStack {
                    RBSystemLabel(
                        text: String(format: "%02d / 05", page + 1),
                        color: .ash
                    )
                    Spacer()
                    if page > 0 {
                        Button {
                            withAnimation(.easeOut(duration: 0.24)) {
                                page -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.ash)
                        }
                    }
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.top, 8)
                Spacer()
            }
            .allowsHitTesting(false)

            RBPhaseTransition(showing: blackout, label: initialized ? "REBOOT INITIALIZED" : "REBOOT / LOCK")
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.28)) {
            page = min(4, page + 1)
        }
        RBHaptics.play(.transition)
    }

    private func commit() {
        guard !blackout else { return }
        RBHaptics.play(.lock)
        withAnimation(RBMotion.lock) {
            blackout = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                initialized = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            onFinish(true)
        }
    }
}
