import SwiftUI

// MARK: - System metadata label

/// Mono uppercase overline: `REBOOT / WAKE UP`.
struct RBSystemLabel: View {
    let text: String
    var color: Color = .ash
    var size: CGFloat = 12

    var body: some View {
        Text(text)
            .font(.metadata(size: size))
            .tracking(1.6)
            .foregroundStyle(color)
            .textCase(.uppercase)
    }
}

// MARK: - Hero statement

/// Display headline with intentional line breaks supplied in the string.
struct RBHeroStatement: View {
    let text: String
    var size: CGFloat = 46
    var color: Color = .bone
    var alignment: TextAlignment = .leading
    var tracking: CGFloat = -0.6

    var body: some View {
        Text(text)
            .font(.heroBlack(size: size))
            .tracking(tracking)
            .lineSpacing(-6)
            .multilineTextAlignment(alignment)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Buttons

struct RBPrimaryButtonStyle: ButtonStyle {
    var scheme: ColorScheme = .dark
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let foreground: Color = scheme == .dark ? .ink : .bone
        let background: Color = scheme == .dark ? .bone : .ink
        configuration.label
            .font(.system(size: 16, weight: .heavy, design: .default))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 17)
            .padding(.horizontal, 26)
            .background(background)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct RBSecondaryButtonStyle: ButtonStyle {
    var scheme: ColorScheme = .dark
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let foreground: Color = scheme == .dark ? .bone : .ink
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .default))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, 26)
            .overlay(
                RoundedRectangle(cornerRadius: RBRadius.sm)
                    .stroke(foreground.opacity(0.35), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == RBPrimaryButtonStyle {
    static func rbPrimary(scheme: ColorScheme = .dark, fullWidth: Bool = true) -> RBPrimaryButtonStyle {
        RBPrimaryButtonStyle(scheme: scheme, fullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == RBSecondaryButtonStyle {
    static func rbSecondary(scheme: ColorScheme = .dark, fullWidth: Bool = true) -> RBSecondaryButtonStyle {
        RBSecondaryButtonStyle(scheme: scheme, fullWidth: fullWidth)
    }
}

// MARK: - Status chip

struct RBStatusChip: View {
    let text: String
    var color: Color = .signalCyan
    var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            RBSignalPulse(color: color, diameter: 6, active: pulse)
            Text(text)
                .font(.metadata(size: 11))
                .tracking(1.5)
                .foregroundStyle(color)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.pill)
                .stroke(color.opacity(0.45), lineWidth: 1)
        )
    }
}

// MARK: - Day counter & phase indicator

struct RBDayCounter: View {
    let day: Int
    var total = 90
    var color: Color = .ash

    var body: some View {
        RBSystemLabel(
            text: "DAY \(String(format: "%03d", day)) / \(String(format: "%03d", total))",
            color: color
        )
    }
}

struct RBPhaseIndicator: View {
    let phase: Int
    var color: Color = .ash

    var body: some View {
        let info = ProtocolCurriculum.phase(forPhase: phase)
        HStack(spacing: 10) {
            RBSystemLabel(text: String(format: "PHASE %02d", phase), color: color)
            Rectangle()
                .fill(color.opacity(0.5))
                .frame(width: 18, height: 1)
            RBSystemLabel(text: info.title, color: color)
        }
    }
}

// MARK: - Metric rail

struct RBMetricRail: View {
    let items: [(label: String, value: String)]
    var valueColor: Color = .signalRed

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                if index > 0 {
                    Rectangle()
                        .fill(Color.line.opacity(0.8))
                        .frame(height: 1)
                        .padding(.vertical, 12)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(item.label)
                        .font(.metadata(size: 12))
                        .tracking(2)
                        .foregroundStyle(.ash)
                        .textCase(.uppercase)
                    Spacer()
                    Text(item.value)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(valueColor)
                        .textCase(.uppercase)
                }
            }
        }
        .padding(18)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line, lineWidth: 1)
        )
    }
}

// MARK: - Editorial divider

struct RBEditorialDivider: View {
    let label: String
    var color: Color = .line

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(color)
                .frame(height: 1)
            Text(label)
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)
                .textCase(.uppercase)
                .layoutPriority(1)
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

// MARK: - Protocol card

struct RBProtocolCard: View {
    let day: ProtocolDay
    var isToday = false
    var isCompleted = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: "%03d", day.dayNumber))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(isToday ? .signalCyan : .ash)
                Text("PHASE \(String(format: "%02d", day.phase))")
                    .font(.metadata(size: 9))
                    .foregroundStyle(.ash.opacity(0.75))
            }
            .frame(width: 46, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(day.mode.label)
                        .font(.metadata(size: 10))
                        .tracking(1.4)
                        .foregroundStyle(accent)
                    if isCompleted {
                        Text("DONE")
                            .font(.metadata(size: 9))
                            .foregroundStyle(.signalCyan)
                    }
                }
                Text(day.title)
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(isToday ? .bone : .softBone)
                    .lineLimit(2)
                Text("\(day.recommendedDuration) MIN")
                    .font(.metadata(size: 10))
                    .foregroundStyle(.ash)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(isToday ? Color.signalCyan.opacity(0.7) : Color.line, lineWidth: 1)
        )
    }

    private var accent: Color {
        day.phase == 1 ? .signalRed : .signalCyan
    }
}

// MARK: - Trace rows

struct RBTraceRow: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedDate)
                    .font(.metadata(size: 10))
                    .tracking(1.2)
                    .foregroundStyle(.ash)
                Text("DAY \(String(format: "%03d", session.protocolDay))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.softBone)
            }
            .frame(width: 74, alignment: .leading)

            Text(session.mode.label)
                .font(.metadata(size: 12))
                .tracking(1.6)
                .foregroundStyle(modeColor)
                .frame(width: 58, alignment: .leading)

            Text("\(session.actualDurationSeconds / 60)M")
                .font(.metadata(size: 12))
                .foregroundStyle(.ash)
                .frame(width: 40, alignment: .leading)

            Spacer()

            if let evaluation = session.evaluation {
                Text(String(format: "%.0f/10", evaluation.overallScore))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.signalCyan)
            } else if session.analysisOffline {
                Text("OFFLINE")
                    .font(.metadata(size: 10))
                    .foregroundStyle(.acid)
            } else {
                Text("—")
                    .font(.metadata(size: 14))
                    .foregroundStyle(.ash.opacity(0.6))
            }
        }
        .padding(.vertical, 13)
    }

    private var modeColor: Color {
        switch session.mode {
        case .stay: return .signalCyan
        case .recall, .explain: return .softBone
        case .nothing: return .ash
        case .observe: return .signalRed
        }
    }
}

struct RBSessionRow: View {
    let mode: SessionMode
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(mode.label)
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(accent)
                Text(mode.frenchLabel)
                    .font(.system(size: 19, weight: .heavy, design: .default))
                    .foregroundStyle(.bone)
                Text(mode.tagline)
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundStyle(.ash)
                    .lineSpacing(2)
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.ash)
                .padding(.top, 6)
        }
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line, lineWidth: 1)
        )
    }
}

// MARK: - Result metric

struct RBResultMetric: View {
    let score: Double
    let label: String
    var color: Color = .signalCyan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%02.0f", score))
                    .font(.system(size: 58, weight: .black, design: .monospaced))
                    .tracking(-1.5)
                    .foregroundStyle(color)
                Text("/ 10")
                    .font(.metadata(size: 16))
                    .foregroundStyle(.ash)
            }
            Text(label)
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Progress timeline

struct RBProgressTimeline: View {
    let currentDay: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ProtocolCurriculum.phases) { phase in
                let active = currentDay >= phase.range.lowerBound
                let current = phase.range.contains(currentDay)
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(active ? (current ? Color.signalCyan : Color.ash.opacity(0.7)) : Color.line, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                        if active {
                            Circle()
                                .fill(current ? Color.signalCyan : Color.ash.opacity(0.7))
                                .frame(width: 5, height: 5)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(String(format: "PHASE %02d", phase.number))
                                .font(.metadata(size: 10))
                                .tracking(1.6)
                                .foregroundStyle(active ? .ash : .ash.opacity(0.45))
                            Text("JOURS \(String(format: "%02d", phase.range.lowerBound))–\(String(format: "%02d", phase.range.upperBound))")
                                .font(.metadata(size: 9))
                                .foregroundStyle(.ash.opacity(0.6))
                        }
                        Text(phase.title)
                            .font(.system(size: 15, weight: .bold, design: .default))
                            .foregroundStyle(active ? .softBone : .ash.opacity(0.5))
                    }
                    Spacer()
                    noiseDots(phase: phase.number)
                }
                .padding(.vertical, 13)
                if phase.number < 4 {
                    Rectangle()
                        .fill(Color.line.opacity(0.8))
                        .frame(height: 1)
                        .padding(.leading, 5)
                }
            }
        }
    }

    @ViewBuilder
    private func noiseDots(phase: Int) -> some View {
        let count = [3, 2, 1, 0][phase - 1]
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < count ? Color.signalRed.opacity(0.8) : Color.line)
                    .frame(width: 4, height: 4)
            }
        }
        .opacity(currentDay >= ProtocolCurriculum.phases[phase - 1].range.lowerBound ? 1 : 0.3)
    }
}

// MARK: - Reconstruction editor

struct RBReconstructionEditor: View {
    @Binding var text: String
    var placeholder: String
    var accent: Color = .signalCyan

    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.reading(size: 18))
                    .foregroundStyle(.ash.opacity(0.65))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(.reading(size: 18))
                .foregroundStyle(.bone)
                .scrollContentBackground(.hidden)
                .padding(12)
                .focused($focused)
        }
        .frame(minHeight: 220, maxHeight: 340)
        .background(Color.graphite)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(focused ? accent : Color.line, lineWidth: 1)
        )
        .onTapGesture {
            focused = true
        }
    }
}

// MARK: - Timer display

struct RBTimerDisplay: View {
    let seconds: Int
    var size: CGFloat = 76
    var color: Color = .bone
    var dimmed = false

    var body: some View {
        Text(formatted)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .tracking(-1)
            .foregroundStyle(color)
            .monospacedDigit()
            .opacity(dimmed ? 0.25 : 1)
    }

    private var formatted: String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lock screen

struct RBLockScreen: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            VStack(spacing: 18) {
                RBStatusChip(text: "STATUS / LOCKED", color: .signalCyan, pulse: true)
                Text(title)
                    .font(.system(size: 24, weight: .heavy, design: .default))
                    .tracking(1)
                    .foregroundStyle(.bone)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.metadata(size: 11))
                        .tracking(1.4)
                        .foregroundStyle(.ash)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Noise primitives

/// A single word fragment in the noise field: jitter + flicker.
struct RBNoiseWord: View {
    let text: String
    var color: Color = .signalRed
    var active = true

    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0.7
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .font(.metadata(size: 11))
            .tracking(2)
            .foregroundStyle(color)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                guard active else { return }
                start()
            }
            .onChange(of: active) { _, isActive in
                if isActive { start() } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = .zero
                        opacity = 0.15
                    }
                }
            }
    }

    private func start() {
        guard !reduceMotion else { return }
        withAnimation(RBMotion.noiseJitter) {
            offset = CGSize(width: CGFloat.random(in: -5...5), height: CGFloat.random(in: -4...4))
            opacity = Double.random(in: 0.35...0.95)
        }
        // Repeat via a small task; cancels when the view disappears.
        Task {
            while active && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 180_000_000...340_000_000))
                guard !Task.isCancelled, !reduceMotion else { return }
                withAnimation(RBMotion.noiseJitter) {
                    offset = CGSize(width: CGFloat.random(in: -6...6), height: CGFloat.random(in: -5...5))
                    opacity = Double.random(in: 0.3...0.95)
                }
            }
        }
    }
}

/// Fragmented interference field used in the NOISE state.
struct RBNoiseField: View {
    var words: [String]
    var active = true
    var tint: Color = .signalRed

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(words.indices, id: \.self) { index in
                    let word = words[index]
                    let slot = noisePosition(index: index, size: geo.size)
                    RBNoiseWord(
                        text: word,
                        color: tint.opacity(index % 3 == 0 ? 1 : 0.7),
                        active: active
                    )
                    .position(slot)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func noisePosition(index: Int, size: CGSize) -> CGPoint {
        let columns = 4
        let col = index % columns
        let row = index / columns
        let x = size.width * (0.16 + CGFloat(col) * 0.24) + CGFloat((index * 37) % 40 - 20)
        let y = size.height * (0.18 + CGFloat(row) * 0.17) + CGFloat((index * 53) % 34 - 17)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Protocol header

struct RBProtocolHeader: View {
    let day: Int
    let phase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RBSystemLabel(text: "REBOOT", color: .bone)
                Spacer()
                RBDayCounter(day: day)
            }
            RBPhaseIndicator(phase: phase)
        }
    }
}

// MARK: - Small signal line decorations

struct RBSignalBracket: View {
    var color: Color = .signalCyan

    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(color).frame(width: 2, height: 26)
            Rectangle().fill(color.opacity(0.35)).frame(width: 2, height: 26)
            Rectangle().fill(color.opacity(0.12)).frame(width: 2, height: 26)
        }
    }
}
