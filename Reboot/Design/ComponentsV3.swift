import SwiftUI

// MARK: - Surface helpers

/// Very subtle radial light field behind an important element.
/// Opacity stays 0.04–0.08 — never neon.
struct RBRadialField: View {
    var color: Color = .signalCyan
    var opacity: Double = 0.06
    var diameter: CGFloat = 260

    var body: some View {
        RadialGradient(
            colors: [color.opacity(opacity), color.opacity(opacity * 0.35), .clear],
            center: .center,
            startRadius: 0,
            endRadius: diameter / 2
        )
        .frame(width: diameter, height: diameter)
        .allowsHitTesting(false)
    }
}

/// Chamfered / cut-corner shape — the signature REBOOT geometry.
struct RBChamferedShape: Shape {
    var cut: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.closeSubpath()
        return path
    }
}

/// Dark panel with one chamfered corner and a thin structural border.
struct RBSignalPlate<Content: View>: View {
    var cut: CGFloat = 16
    var accent: Color = .line
    var fill: Color = .deepCarbon
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(fill)
            .clipShape(RBChamferedShape(cut: cut))
            .overlay(
                RBChamferedShape(cut: cut)
                    .stroke(accent.opacity(0.55), lineWidth: 1)
            )
    }
}

/// High-contrast Bone surface with one cut corner and an asymmetric notch.
struct RBBonePlate<Content: View>: View {
    var cut: CGFloat = 22
    var notch = true
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(Color.bonePlate)
            .clipShape(RBChamferedShape(cut: cut))
            .overlay(alignment: .topTrailing) {
                if notch {
                    RBChamferedShape(cut: 12)
                        .fill(Color.void)
                        .frame(width: 24, height: 24)
                        .offset(x: 2, y: -2)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RBChamferedShape(cut: cut))
    }
}

// MARK: - Instruments

/// Circular / semi-circular program instrument. Not a generic progress ring:
/// an arc with a phase node and a signal marker.
struct RBSignalCore: View {
    let day: Int
    let total: Int
    let phase: Int
    var size: CGFloat = 190
    var lineWidth: CGFloat = 7

    private var progress: Double {
        min(1, max(0, Double(day) / Double(total)))
    }

    private var accent: Color {
        Color.phaseAccent(phase)
    }

    var body: some View {
        ZStack {
            RBRadialField(color: accent, opacity: 0.07, diameter: size + 40)
            Circle()
                .stroke(Color.line.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.signalRed, accent, .signalCyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: RBMotion.hero), value: progress)
            // Phase marker nodes
            ForEach(1...4, id: \.self) { p in
                let angle = -90 + Double(p - 1) * (90 / 3.0)
                Circle()
                    .fill(phase >= p ? Color.phaseAccent(p) : Color.line.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(angle))
            }
            VStack(spacing: 2) {
                Text(String(format: "%03d", day))
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .tracking(-1.5)
                    .foregroundStyle(.bone)
                    .contentTransition(.numericText())
                Text("/ \(total)")
                    .font(.metadata(size: 12))
                    .foregroundStyle(.ash)
                Text("PHASE \(String(format: "%02d", phase))")
                    .font(.metadata(size: 9))
                    .tracking(2)
                    .foregroundStyle(accent)
                    .padding(.top, 4)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Calibration instrument: incomplete 3-part ring, no invented number.
struct RBCalibrationCore: View {
    let completed: Int
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .trim(from: CGFloat(index) / 3 + 0.035, to: CGFloat(index + 1) / 3 - 0.035)
                    .stroke(
                        index < completed ? Color.signalCyan : Color.line.opacity(0.5),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text("\(completed)")
                    .font(.system(size: 30, weight: .black, design: .monospaced))
                    .foregroundStyle(.bone)
                    .contentTransition(.numericText())
                Text("/ 3")
                    .font(.metadata(size: 10))
                    .foregroundStyle(.ash)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Segmented horizontal information rail (Focus, Stability, Recall, Depth).
struct RBMetricInstrument: View {
    let label: String
    let value: Double?
    var segments = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.metadata(size: 10))
                    .tracking(2)
                    .foregroundStyle(.ash)
                Spacer()
                Text(value.map { String(format: "%.1f", $0) } ?? "—")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(value != nil ? .signalCyan : .ash.opacity(0.5))
                    .contentTransition(.numericText())
            }
            HStack(spacing: 4) {
                ForEach(0..<segments, id: \.self) { index in
                    let filled = value.map { index < Int(($0 / 10.0 * Double(segments)).rounded()) } ?? false
                    Capsule()
                        .fill(filled ? Color.signalCyan : Color.line.opacity(0.5))
                        .frame(height: 5)
                }
            }
        }
    }
}

/// Small signal wave — ambient subtle pulse, not endless decoration.
struct RBSignalWave: View {
    var color: Color = .signalCyan
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height / 2))
            for x in stride(from: 0.0, through: size.width, by: 2) {
                let y = size.height / 2 + sin((x / size.width * 6.28) + phase * 6.28) * size.height * 0.22
                path.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(path, with: .color(color.opacity(0.7)), lineWidth: 1.5)
        }
        .frame(height: 22)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Data blocks & nodes

struct RBDataBlock: View {
    let label: String
    let value: String
    var accent: Color = .signalCyan

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.metadata(size: 9))
                .tracking(1.8)
                .foregroundStyle(.ash)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.graphiteSurface)
        .clipShape(RBChamferedShape(cut: 10))
    }
}

struct RBInsightStrip: View {
    let text: String
    var accent: Color = .acid

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(accent)
                .frame(width: 3, height: 40)
            Text(text)
                .font(.body(size: 14))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color.deepCarbon)
        .clipShape(RBChamferedShape(cut: 12))
    }
}

/// Timeline node used on the Program track and Trace.
struct RBTimelineNode: View {
    var state: NodeState
    var size: CGFloat = 14

    enum NodeState {
        case current
        case completed
        case future
        case milestone
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: size, height: size)
            if state == .current {
                Circle()
                    .stroke(Color.signalCyan, lineWidth: 2)
                    .frame(width: size + 7, height: size + 7)
            }
            if state == .milestone {
                Circle()
                    .stroke(Color.signalCyan.opacity(0.5), lineWidth: 1)
                    .frame(width: size + 13, height: size + 13)
            }
        }
    }

    private var fill: Color {
        switch state {
        case .current: return .signalCyan
        case .completed: return .signalCyan.opacity(0.55)
        case .future: return .graphiteSurface
        case .milestone: return .signalCyan
        }
    }
}

// MARK: - Buttons V3

/// A — Primary system action: bone plate, one clipped corner, once per screen.
struct RBSystemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .heavy, design: .default))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.bonePlate)
            .clipShape(RBChamferedShape(cut: 16))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: RBMotion.fast), value: configuration.isPressed)
    }
}

/// B — Signal action: dark surface, cyan line, directional marker.
struct RBActionPlateStyle: ButtonStyle {
    var accent: Color = .signalCyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .default))
            .tracking(1.1)
            .foregroundStyle(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 12))
            .overlay(
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
                    .frame(maxWidth: 90, alignment: .leading)
                    .padding(.leading, 16),
                alignment: .bottomLeading
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: RBMotion.fast), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RBSystemButtonStyle {
    static var rbSystem: RBSystemButtonStyle { RBSystemButtonStyle() }
}

extension ButtonStyle where Self == RBActionPlateStyle {
    static func rbActionPlate(accent: Color = .signalCyan) -> RBActionPlateStyle {
        RBActionPlateStyle(accent: accent)
    }
}

// MARK: - Mode glyphs

enum RBModeGlyphKind {
    case stay, recall, explain, nothing, observe

    var accent: Color {
        switch self {
        case .stay: return .signalCyan
        case .recall: return .softBone
        case .explain: return .acid
        case .nothing: return .ash
        case .observe: return .signalRed
        }
    }
}

/// Custom vector glyphs for the five disciplines — no generic SF Symbols here.
struct RBModeGlyph: View {
    let kind: RBModeGlyphKind
    var size: CGFloat = 30

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let stroke = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            let accent = kind.accent
            var path = Path()
            switch kind {
            case .stay:
                // closed horizontal gate
                path.move(to: CGPoint(x: 3, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width - 3, y: size.height / 2))
                path.move(to: CGPoint(x: size.width / 2, y: 3))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 3))
            case .recall:
                // open book: two arcs
                path.move(to: CGPoint(x: size.width / 2, y: 4))
                path.addQuadCurve(to: CGPoint(x: 3, y: size.height * 0.55), control: CGPoint(x: size.width * 0.25, y: size.height * 0.35))
                path.move(to: CGPoint(x: size.width / 2, y: 4))
                path.addQuadCurve(to: CGPoint(x: size.width - 3, y: size.height * 0.55), control: CGPoint(x: size.width * 0.75, y: size.height * 0.35))
                path.move(to: CGPoint(x: size.width / 2, y: 4))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 3))
            case .explain:
                // radiating speech: center + three lines
                path.move(to: CGPoint(x: size.width / 2, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width / 2, y: 3))
                path.move(to: CGPoint(x: size.width / 2, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width - 3, y: size.height - 5))
                path.move(to: CGPoint(x: size.width / 2, y: size.height / 2))
                path.addLine(to: CGPoint(x: 3, y: size.height - 5))
            case .nothing:
                // single calm dot with wide orbit
                path.addEllipse(in: CGRect(x: size.width / 2 - 2, y: size.height / 2 - 2, width: 4, height: 4))
                path.addEllipse(in: rect.insetBy(dx: size.width * 0.18, dy: size.height * 0.18))
            case .observe:
                // eye: arc + pupil
                path.move(to: CGPoint(x: 3, y: size.height / 2))
                path.addQuadCurve(to: CGPoint(x: size.width - 3, y: size.height / 2), control: CGPoint(x: size.width / 2, y: size.height * 0.18))
                path.move(to: CGPoint(x: size.width - 3, y: size.height / 2))
                path.addQuadCurve(to: CGPoint(x: 3, y: size.height / 2), control: CGPoint(x: size.width / 2, y: size.height * 0.82))
                path.addEllipse(in: CGRect(x: size.width / 2 - 3, y: size.height / 2 - 3, width: 6, height: 6))
            }
            context.stroke(path, with: .color(accent), style: stroke)
        }
        .frame(width: size, height: size)
    }
}

/// Distinct spatial identity for each discipline module.
struct RBModeNode: View {
    let kind: RBModeGlyphKind
    let index: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.deepCarbon)
            RBModeGlyph(kind: kind, size: 30)
                .padding(18)
            Text(String(format: "%02d", index))
                .font(.system(size: 44, weight: .black, design: .monospaced))
                .foregroundStyle(kind.accent.opacity(0.18))
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, -6)
        }
        .clipShape(chamfer)
    }

    private var chamfer: RBChamferedShape {
        switch index % 4 {
        case 1: return RBChamferedShape(cut: 26)
        case 2: return RBChamferedShape(cut: 0)
        case 3: return RBChamferedShape(cut: 26)
        default: return RBChamferedShape(cut: 0)
        }
    }
}

/// Compact protocol phase band used on Today.
struct RBPhaseBand: View {
    let phase: Int
    let currentDay: Int
    var onTap: () -> Void

    var body: some View {
        let info = ProtocolCurriculum.phase(forPhase: phase)
        let active = currentDay >= info.range.lowerBound
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(String(format: "%02d", phase))
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(active ? Color.phaseAccent(phase) : .ash.opacity(0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title)
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundStyle(active ? .bone : .ash.opacity(0.55))
                    Text("JOURS \(String(format: "%02d", info.range.lowerBound))–\(String(format: "%02d", info.range.upperBound))")
                        .font(.metadata(size: 9))
                        .foregroundStyle(.ash.opacity(0.7))
                }
                Spacer()
                if info.range.contains(currentDay) {
                    RBSignalPulse(color: .signalCyan, diameter: 6, active: true)
                }
            }
            .padding(12)
            .background(active ? Color.graphiteSurface : Color.deepCarbon)
            .clipShape(RBChamferedShape(cut: 10))
            .overlay(
                RBChamferedShape(cut: 10)
                    .stroke(active ? Color.phaseAccent(phase).opacity(0.5) : Color.line.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Thin floating carbon tab dock with a small cyan signal field on selection.
struct RBDockTabBar<Tab: Hashable>: View {
    @Binding var selection: Tab
    let tabs: [(tab: Tab, label: String)]
    @Namespace private var field

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tab) { item in
                Button {
                    withAnimation(RBMotion.tabTransition) {
                        selection = item.tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(item.label)
                            .font(.system(size: 10, weight: .bold, design: .default))
                            .tracking(1.4)
                            .foregroundStyle(selection == item.tab ? .bone : .ash)
                        ZStack {
                            if selection == item.tab {
                                Capsule()
                                    .fill(Color.signalCyan.opacity(0.28))
                                    .frame(width: 26, height: 3)
                                    .matchedGeometryEffect(id: "tabfield", in: field)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(width: 26, height: 3)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color.deepCarbon.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.line.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }
}
