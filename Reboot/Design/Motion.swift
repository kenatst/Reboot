import SwiftUI

/// Central motion vocabulary. Duration range is intentionally tight (120–350ms).
enum RBMotion {
    static let fast: Double = 0.12
    static let standard: Double = 0.24
    static let slow: Double = 0.35

    static func duration(_ base: Double, reduceMotion: Bool) -> Double {
        reduceMotion ? 0.0 : base
    }

    static let noiseJitter = Animation.easeOut(duration: 0.18)
    static let signalPulse = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)

    /// Phase transition easing: rapid reduction, no bounce.
    static let lock = Animation.easeIn(duration: 0.32)
    static let recovery = Animation.easeOut(duration: 0.34)
}

/// A signal line that draws itself left-to-right.
struct RBSignalLine: View {
    var color: Color = .signalCyan
    var thickness: CGFloat = 2
    var draws = true

    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.16))
                Rectangle()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: thickness)
        .onAppear {
            guard draws else { return }
            withAnimation(.easeOut(duration: RBMotion.duration(0.8, reduceMotion: reduceMotion))) {
                progress = 1
            }
        }
    }
}

/// Cyan confirmation pulse (a dot that breathes once, not endlessly).
struct RBSignalPulse: View {
    var color: Color = .signalCyan
    var diameter: CGFloat = 8
    var active = true

    @State private var scale: CGFloat = 0.6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .scaleEffect(scale)
            .opacity(active ? 1 : 0.35)
            .onAppear {
                guard active else { return }
                withAnimation(.easeOut(duration: RBMotion.duration(0.45, reduceMotion: reduceMotion))) {
                    scale = 1
                }
            }
    }
}

/// Horizontal scan line that travels once from top to bottom of its frame.
struct RBScanLine: View {
    var color: Color = .signalRed.opacity(0.6)
    @State private var position: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(color)
                .frame(height: 1.5)
                .offset(y: geo.size.height * position - geo.size.height / 2)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                position = 1
            }
        }
    }
}

/// Hard full-screen transition used when locking into a session.
struct RBPhaseTransition: View {
    var showing: Bool
    var label: String
    var color: Color = .void

    var body: some View {
        ZStack {
            color
                .ignoresSafeArea()
            VStack(spacing: 16) {
                RBStatusChip(text: label, color: .signalCyan)
                if showing {
                    RBSignalPulse()
                }
            }
        }
        .opacity(showing ? 1 : 0)
        .animation(.easeInOut(duration: RBMotion.slow), value: showing)
        .allowsHitTesting(showing)
    }
}
