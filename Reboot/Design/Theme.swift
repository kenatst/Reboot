import SwiftUI
import UIKit

// MARK: - Semantic colors

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

extension ShapeStyle where Self == Color {
    /// Primary dark background.
    static var void: Color { Color(hex: 0x080A09) }
    /// Primary light background.
    static var bone: Color { Color(hex: 0xF2EEE5) }
    static var ink: Color { Color(hex: 0x101916) }
    static var graphite: Color { Color(hex: 0x171A19) }
    /// Alarm / overload.
    static var signalRed: Color { Color(hex: 0xFF4438) }
    /// Recovered signal / active system.
    static var signalCyan: Color { Color(hex: 0x57E6FF) }
    /// Occasional warning.
    static var acid: Color { Color(hex: 0xF1E45A) }
    static var ash: Color { Color(hex: 0x858C89) }
    static var line: Color { Color(hex: 0x303633) }
    static var softBone: Color { Color(hex: 0xE7E1D6) }
}

extension Color {
    /// Phase-driven accent. Phase I leans red, later phases lean cyan.
    static func phaseAccent(_ phase: Int) -> Color {
        switch phase {
        case 1: return .signalRed
        case 2: return .signalRed.mixed(with: .signalCyan, amount: 0.35)
        default: return .signalCyan
        }
    }

    func mixed(with other: Color, amount: Double) -> Color {
        let c1 = UIColor(self)
        let c2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(amount)
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t)
        )
    }
}

// MARK: - Typography

extension Font {
    /// Hero display: SF Pro Display heavy, tight tracking.
    static func hero(size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }

    static func heroBlack(size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func body(size: CGFloat = 18) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// System metadata: SF Mono uppercase micro labels.
    static func metadata(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// Reading serif body.
    static func reading(size: CGFloat = 19) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}

// MARK: - Spacing & layout

enum RBSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let xl: CGFloat = 40
    static let screen: CGFloat = 24
}

enum RBRadius {
    static let none: CGFloat = 0
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let pill: CGFloat = 999
}

// MARK: - Text helpers

extension String {
    /// "ton attention" -> "TON ATTENTION" (uppercase French with accents).
    var uppercasedFR: String {
        uppercased()
    }
}

// MARK: - Haptics

enum RBHapticKind {
    case interruption
    case transition
    case lock
}

/// Routes haptic feedback through user preferences (respects system setting too).
@MainActor
enum RBHaptics {
    private static var enabled: Bool {
        PreferencesStore.shared.hapticsEnabled
    }

    static func play(_ kind: RBHapticKind) {
        guard enabled else { return }
        switch kind {
        case .interruption:
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
        case .transition:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .lock:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        }
    }
}
