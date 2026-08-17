import SwiftUI

/// Custom onboarding container — no TabView paging. Each transition is
/// authored: freeze, scan, micro blackout, drain, line morph, compress.
struct OnboardingFlowView: View {
    var initialPage = 0
    var onFinish: (Bool) -> Void = { _ in }

    @State private var page: Int
    @State private var transition: OBTransition?
    @State private var beginCeremony = false
    @State private var initialized = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(initialPage: Int = 0, onFinish: @escaping (Bool) -> Void = { _ in }) {
        self.initialPage = initialPage
        self.onFinish = onFinish
        self._page = State(initialValue: initialPage)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            currentPage
                .id(page)
                .transition(.opacity)

            progressChrome
                .allowsHitTesting(false)

            if let transition {
                transition.overlay(reduceMotion: reduceMotion)
                    .transition(.opacity)
                    .zIndex(20)
            }

            if beginCeremony {
                beginOverlay
                    .transition(.opacity)
                    .zIndex(30)
            }
        }
        .animation(.easeInOut(duration: RBMotion.duration(0.3, reduceMotion: reduceMotion)), value: page)
        .onAppear {
            #if DEBUG
            if UITestDriver.autoAdvanceOnboarding {
                Task {
                    for _ in 0..<4 {
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        guard transition == nil else { continue }
                        advance()
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    begin()
                }
            }
            #endif
        }
    }

    @ViewBuilder
    private var currentPage: some View {
        switch page {
        case 0: OnboardingAttackView(advance: advance)
        case 1: OnboardingDiagnosticView(advance: advance)
        case 2: OnboardingContrastView(advance: advance)
        case 3: OnboardingProtocolView(advance: advance)
        default: OnboardingContractView(commit: begin, skip: { onFinish(false) })
        }
    }

    private var progressChrome: some View {
        VStack {
            HStack {
                RBSystemLabel(
                    text: String(format: "%02d / 05", page + 1),
                    color: .ash
                )
                Spacer()
                if page > 0 && transition == nil {
                    Button {
                        withAnimation(RBMotion.standardAnim) {
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
    }

    private func advance() {
        guard transition == nil, page < 4 else { return }
        let kind: OBTransition = {
            switch page {
            case 0: return .toDiagnostic
            case 1: return .toSignal
            case 2: return .toProtocol
            default: return .toContract
            }
        }()
        runTransition(kind, target: page + 1)
    }

    private func runTransition(_ kind: OBTransition, target: Int) {
        RBHaptics.play(.transition)
        withAnimation(.easeOut(duration: RBMotion.duration(0.18, reduceMotion: reduceMotion))) {
            transition = kind
        }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(kind.duration * 1_000_000_000))
            withAnimation(.easeInOut(duration: RBMotion.duration(0.28, reduceMotion: reduceMotion))) {
                page = target
                transition = nil
            }
            if kind == .toSignal {
                RBHaptics.play(.transition)
            }
        }
    }

    private func begin() {
        guard beginCeremony == false else { return }
        RBHaptics.play(.lock)
        withAnimation(RBMotion.lock) {
            beginCeremony = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                initialized = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            onFinish(true)
        }
    }

    private var beginOverlay: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if !initialized {
                VStack {
                    Spacer()
                    RBSignalLine(color: .signalCyan, thickness: 2)
                        .frame(width: 320)
                    Spacer()
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 14) {
                    RBSignalPulse(color: .signalCyan, diameter: 8, active: true)
                    Text("REBOOT")
                        .font(.heroBlack(size: 44))
                        .tracking(-0.5)
                        .foregroundStyle(.bone)
                    Text("INITIALIZED")
                        .font(.metadata(size: 12))
                        .tracking(3)
                        .foregroundStyle(.signalCyan)
                    Text("DAY 001")
                        .font(.metadata(size: 11))
                        .tracking(2)
                        .foregroundStyle(.ash)
                        .padding(.top, 6)
                }
                .transition(.opacity)
            }
        }
    }
}

/// Authored transition phases between onboarding pages.
enum OBTransition {
    case toDiagnostic
    case toSignal
    case toProtocol
    case toContract

    var duration: Double {
        switch self {
        case .toDiagnostic: return 0.65
        case .toSignal: return 0.85
        case .toProtocol: return 0.60
        case .toContract: return 0.55
        }
    }

    @ViewBuilder
    func overlay(reduceMotion: Bool) -> some View {
        switch self {
        case .toDiagnostic:
            OBTransitionOverlay(freeze: true, scan: true)
        case .toSignal:
            OBTransitionOverlay(freeze: true, drain: true)
        case .toProtocol:
            OBTransitionOverlay(lineMorph: true)
        case .toContract:
            OBTransitionOverlay(compress: true)
        }
    }
}

struct OBTransitionOverlay: View {
    var freeze = false
    var scan = false
    var drain = false
    var lineMorph = false
    var compress = false

    @State private var scanOffset: CGFloat = -1
    @State private var cyanVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            if drain {
                Rectangle()
                    .fill(Color.signalRed.opacity(0.22))
                    .ignoresSafeArea()
                    .transition(.opacity)
                RBRadialField(color: .signalCyan, opacity: 0.10, diameter: 300)
                    .opacity(cyanVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: RBMotion.duration(0.3, reduceMotion: reduceMotion)).delay(0.38)) {
                            cyanVisible = true
                        }
                    }
            }

            if scan {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.signalRed.opacity(0.55))
                        .frame(height: 1.5)
                        .offset(y: geo.size.height * scanOffset)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: 0.55)) {
                        scanOffset = 1
                    }
                }
            }

            if lineMorph {
                RBSignalLine(color: .signalCyan, thickness: 2)
                    .frame(width: 240)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.4)
            }

            if compress {
                Rectangle()
                    .fill(Color.void)
                    .scaleEffect(x: 0.001, y: 1)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeIn(duration: RBMotion.duration(0.45, reduceMotion: reduceMotion))) {
                            scanOffset = 0
                        }
                    }
            }
        }
    }
}
