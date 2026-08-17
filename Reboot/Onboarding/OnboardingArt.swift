import SwiftUI

/// Bundled onboarding artwork (preprocessed from "onb no wr.zip").
enum OnboardingArt {
    static let overload = "OnboardingOverload"
    static let diagnostic = "OnboardingDiagnostic"
    static let recovery = "OnboardingRecovery"
    static let protocolArt = "OnboardingProtocol"
    static let activation = "OnboardingActivation"
    static let signal = "OnboardingSignal"

    /// Renders artwork without hard rectangle edges: the masked PNG is drawn
    /// over VOID so its glow blends into the composition.
    @ViewBuilder
    static func render(
        _ name: String,
        contentMode: ContentMode = .fit,
        opacity: Double = 1
    ) -> some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: contentMode)
            .opacity(opacity)
    }
}

/// Small overlay used to anchor qualitative diagnostic labels on the artwork.
struct RBDiagnosticTag: View {
    let label: String
    let value: String
    var valueColor: Color = .signalRed
    var alignment: Alignment = .leading

    var body: some View {
        VStack(alignment: alignment == .leading ? .leading : .trailing, spacing: 3) {
            Text(label)
                .font(.metadata(size: 9))
                .tracking(2)
                .foregroundStyle(.ash)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(valueColor)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.void.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(valueColor.opacity(0.35), lineWidth: 1)
        )
    }
}

/// Bottom scrim that guarantees essential text stays readable over artwork.
struct RBArtScrim: View {
    var body: some View {
        LinearGradient(
            colors: [Color.void.opacity(0.0), Color.void.opacity(0.55), Color.void.opacity(0.96)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
