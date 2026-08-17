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

// MARK: - Hero statement & responsive typography

/// Display headline with intentional line breaks supplied in the string,
/// respecting word boundaries and adapting cleanly to screen width.
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
            .lineSpacing(-4)
            .multilineTextAlignment(alignment)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Hero title that guarantees words will NEVER break inside a word (e.g. CONCENTRATION stays intact).
struct RBNonBreakingHero: View {
    let title: String
    var baseSize: CGFloat = 42
    var color: Color = .bone
    var tracking: CGFloat = -0.5

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(title)
                .font(.heroBlack(size: baseSize))
                .tracking(tracking)
                .foregroundStyle(color)
                .lineLimit(1)
            
            Text(title)
                .font(.heroBlack(size: baseSize * 0.85))
                .tracking(tracking)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.heroBlack(size: baseSize * 0.72))
                .tracking(tracking)
                .foregroundStyle(color)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Button system

/// Signature primary action: Bone filled, black text. Used for Begin, Lock, Complete.
struct RBPrimaryButtonStyle: ButtonStyle {
    var scheme: ColorScheme = .dark
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let foreground: Color = scheme == .dark ? .ink : .bone
        let background: Color = scheme == .dark ? .bone : .ink
        configuration.label
            .font(.system(size: 15, weight: .heavy, design: .default))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(background)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Secondary action: Subtle border with bone/ash text.
struct RBSecondaryButtonStyle: ButtonStyle {
    var scheme: ColorScheme = .dark
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let foreground: Color = scheme == .dark ? .bone : .ink
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .default))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .overlay(
                RoundedRectangle(cornerRadius: RBRadius.sm)
                    .stroke(foreground.opacity(0.35), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Signal action: Transparent/dark, cyan border, cyan text. Used for Retry, secondary protocol actions.
struct RBSignalButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .default))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Color.signalCyan)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(Color.signalCyan.opacity(configuration.isPressed ? 0.12 : 0.04))
            .overlay(
                RoundedRectangle(cornerRadius: RBRadius.sm)
                    .stroke(Color.signalCyan.opacity(0.6), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Text action: No container, subtle ash/bone hover. Used for back, skip, optional challenges.
struct RBTextButtonStyle: ButtonStyle {
    var color: Color = .ash

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.metadata(size: 11))
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundStyle(configuration.isPressed ? Color.bone : color)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Danger action: Red minimal treatment. Used for reset/delete.
struct RBDangerButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .default))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Color.signalRed)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 13)
            .padding(.horizontal, 20)
            .overlay(
                RoundedRectangle(cornerRadius: RBRadius.sm)
                    .stroke(Color.signalRed.opacity(0.4), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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

extension ButtonStyle where Self == RBSignalButtonStyle {
    static func rbSignal(fullWidth: Bool = true) -> RBSignalButtonStyle {
        RBSignalButtonStyle(fullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == RBTextButtonStyle {
    static func rbText(color: Color = .ash) -> RBTextButtonStyle {
        RBTextButtonStyle(color: color)
    }
}

extension ButtonStyle where Self == RBDangerButtonStyle {
    static func rbDanger(fullWidth: Bool = true) -> RBDangerButtonStyle {
        RBDangerButtonStyle(fullWidth: fullWidth)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(session.formattedDate)
                    .font(.metadata(size: 10))
                    .tracking(1.2)
                    .foregroundStyle(.ash)
                
                Text("DAY \(String(format: "%03d", session.protocolDay))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.softBone)
                
                Spacer()
                
                Text("\(session.actualDurationSeconds / 60)M")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.ash)
            }

            HStack(alignment: .center, spacing: 10) {
                Circle()
                    .fill(modeColor)
                    .frame(width: 5, height: 5)
                
                Text(session.mode.label)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(.bone)
                    .lineLimit(1)
                    .layoutPriority(2)

                if !session.title.isEmpty {
                    Text("·")
                        .foregroundStyle(.ash.opacity(0.5))
                    Text(session.title)
                        .font(.body(size: 13))
                        .foregroundStyle(.ash)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                }

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
        }
        .padding(.vertical, 14)
    }

    private var modeColor: Color {
        switch session.mode {
        case .stay: return .signalCyan
        case .recall: return .bone
        case .explain: return .softBone
        case .nothing: return .ash
        case .observe: return .signalRed
        }
    }
}

struct RBSessionRow: View {
    let index: Int
    let mode: SessionMode
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%02d / %@", index, mode.label))
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(accent)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.ash.opacity(0.7))
            }
            .padding(.bottom, 8)

            Text(mode.frenchLabel)
                .font(.system(size: 20, weight: .black, design: .default))
                .foregroundStyle(.bone)
                .lineLimit(1)
                .padding(.bottom, 6)

            Text(mode.tagline.replacingOccurrences(of: "\n", with: " "))
                .font(.body(size: 13))
                .foregroundStyle(.ash)
                .lineLimit(1)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.graphite.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line.opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Protocol Vector Glyphs

enum RBProtocolGlyphKind {
    case today
    case train
    case trace
    case profile
}

struct RBProtocolGlyph: View {
    let kind: RBProtocolGlyphKind
    var color: Color = .ash
    var isSelected: Bool = false
    var size: CGFloat = 20

    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let strokeColor = isSelected ? Color.signalCyan : color
            let fillColor = isSelected ? Color.signalCyan : color

            switch kind {
            case .today:
                // TODAY = signal / filled core (inner filled core + outer precision ring segment)
                let radius: CGFloat = 8
                context.stroke(
                    Path { p in
                        p.addArc(center: center, radius: radius, startAngle: .degrees(-140), endAngle: .degrees(140), clockwise: false)
                    },
                    with: .color(strokeColor),
                    lineWidth: 1.8
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7)),
                    with: .color(fillColor)
                )

            case .train:
                // TRAIN = split square / training block
                let bSize: CGFloat = 6.5
                let gap: CGFloat = 2.5
                // Top left
                context.stroke(
                    Path(roundedRect: CGRect(x: center.x - bSize - gap/2, y: center.y - bSize - gap/2, width: bSize, height: bSize), cornerRadius: 1),
                    with: .color(strokeColor),
                    lineWidth: 1.5
                )
                // Top right (filled if selected)
                if isSelected {
                    context.fill(
                        Path(roundedRect: CGRect(x: center.x + gap/2, y: center.y - bSize - gap/2, width: bSize, height: bSize), cornerRadius: 1),
                        with: .color(fillColor)
                    )
                } else {
                    context.stroke(
                        Path(roundedRect: CGRect(x: center.x + gap/2, y: center.y - bSize - gap/2, width: bSize, height: bSize), cornerRadius: 1),
                        with: .color(strokeColor),
                        lineWidth: 1.5
                    )
                }
                // Bottom left
                context.stroke(
                    Path(roundedRect: CGRect(x: center.x - bSize - gap/2, y: center.y + gap/2, width: bSize, height: bSize), cornerRadius: 1),
                    with: .color(strokeColor),
                    lineWidth: 1.5
                )
                // Bottom right
                context.stroke(
                    Path(roundedRect: CGRect(x: center.x + gap/2, y: center.y + gap/2, width: bSize, height: bSize), cornerRadius: 1),
                    with: .color(strokeColor),
                    lineWidth: 1.5
                )

            case .trace:
                // TRACE = directional trace / triangular signal
                var path = Path()
                let h: CGFloat = 16
                let w: CGFloat = 15
                path.move(to: CGPoint(x: center.x, y: center.y - h/2))
                path.addLine(to: CGPoint(x: center.x + w/2, y: center.y + h/2))
                path.addLine(to: CGPoint(x: center.x - w/2, y: center.y + h/2))
                path.closeSubpath()
                context.stroke(path, with: .color(strokeColor), lineWidth: 1.6)
                if isSelected {
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y + 1, width: 5, height: 5)),
                        with: .color(fillColor)
                    )
                }

            case .profile:
                // PROFILE = structured node / hexagonal profile
                var path = Path()
                let r: CGFloat = 8.5
                for i in 0..<6 {
                    let angle = Double(i) * .pi / 3.0 - .pi / 6.0
                    let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
                    if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(strokeColor), lineWidth: 1.6)
                if isSelected {
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)),
                        with: .color(fillColor)
                    )
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Horizontal Signal Rail

struct RBSignalRail: View {
    let label: String
    let score: Double?
    var maxScore: Double = 10.0
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(.ash)
                Spacer()
                if let score {
                    Text(String(format: "%.1f/10", score))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.signalCyan)
                } else {
                    Text("—")
                        .font(.metadata(size: 13))
                        .foregroundStyle(.ash.opacity(0.5))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(Color.line.opacity(0.8))
                        .frame(height: 3)
                    
                    // Segments marks
                    HStack(spacing: 0) {
                        ForEach(0..<10, id: \.self) { i in
                            Rectangle()
                                .fill(Color.void)
                                .frame(width: 1.5, height: 3)
                            if i < 9 {
                                Spacer()
                            }
                        }
                    }

                    // Active fill
                    if let score {
                        let fillWidth = max(0, min(geo.size.width, geo.size.width * CGFloat(score / maxScore)))
                        Rectangle()
                            .fill(Color.signalCyan)
                            .frame(width: fillWidth, height: 3)
                    }
                }
            }
            .frame(height: 3)

            if let note, !note.isEmpty {
                Text(note)
                    .font(.body(size: 12))
                    .foregroundStyle(.ash)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
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

// MARK: - Custom Bottom Navigation Bar

struct RBCustomTabBar<Tab: Hashable>: View {
    @Binding var selection: Tab
    let tabs: [(tab: Tab, label: String, glyph: RBProtocolGlyphKind)]
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tab) { item in
                let isSelected = selection == item.tab
                Button {
                    if selection != item.tab {
                        RBHaptics.play(.selection)
                        withAnimation(RBMotion.tabTransition) {
                            selection = item.tab
                        }
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            // Refined industrial capsule with ~25% reduced mass
                            RoundedRectangle(cornerRadius: RBRadius.pill)
                                .fill(Color.graphite.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: RBRadius.pill)
                                        .stroke(Color.line.opacity(0.9), lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "activeTabCapsule", in: tabNamespace)
                                .frame(height: 48)
                                .padding(.horizontal, 4)
                        }

                        VStack(spacing: 4) {
                            RBProtocolGlyph(
                                kind: item.glyph,
                                color: isSelected ? .signalCyan : .ash.opacity(0.8),
                                isSelected: isSelected,
                                size: 18
                            )

                            Text(item.label)
                                .font(.metadata(size: 9))
                                .tracking(1.2)
                                .foregroundStyle(isSelected ? Color.bone : Color.ash.opacity(0.7))
                                .textCase(.uppercase)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            Color.void.opacity(0.96)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.line.opacity(0.6))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
