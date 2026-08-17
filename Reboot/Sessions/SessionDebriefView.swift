import SwiftUI
import SwiftData

/// Results are debriefs, not rewards.
struct SessionDebriefView: View {
    let session: TrainingSession
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext

    enum AnalysisState {
        case idle
        case analyzing
        case success
        case offline
    }

    @State private var analysis: AnalysisState = .idle
    @State private var calm = 3
    @State private var energy = 3
    @State private var subjectiveSaved = false

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if needsAnalysis {
                        analysisSection
                    } else {
                        sessionStats
                    }
                    subjectiveSection
                    Button(action: onFinish) {
                        HStack {
                            Text("TERMINER")
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 28)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .onAppear {
            if needsAnalysis && !session.analysisAttempted {
                runAnalysis()
            }
        }
        .statusBarHidden()
    }

    private var needsAnalysis: Bool {
        session.mode == .recall || session.mode == .explain
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RBSystemLabel(text: "REBOOT / \(session.mode.label)", color: .signalCyan)
                Spacer()
                RBDayCounter(day: session.protocolDay)
            }
            .padding(.top, 14)

            Text("SESSION / ANALYZED")
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)
                .padding(.top, 30)

            if let evaluation = session.evaluation, analysis == .success {
                RBResultMetric(score: evaluation.overallScore, label: "SESSION / ANALYZED")
                    .padding(.top, 14)
            } else {
                Text(session.mode.label)
                    .font(.heroBlack(size: 44))
                    .foregroundStyle(.bone)
                    .padding(.top, 10)
            }

            Text("\(session.formattedDate) · \(session.actualDurationSeconds / 60) MIN · DAY \(String(format: "%03d", session.protocolDay))")
                .font(.metadata(size: 10))
                .tracking(1.2)
                .foregroundStyle(.ash)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var analysisSection: some View {
        switch analysis {
        case .idle, .analyzing:
            VStack(alignment: .leading, spacing: 14) {
                RBScanLine(color: .signalCyan.opacity(0.5))
                    .frame(height: 60)
                RBSystemLabel(text: "ANALYSING…", color: .signalCyan)
            }
            .padding(.top, 26)
        case .success:
            if let evaluation = session.evaluation {
                VStack(alignment: .leading, spacing: 0) {
                    dimensionRail(evaluation)
                    debriefBlock(title: "WHAT HELD", text: evaluation.strength, color: .signalCyan)
                    debriefBlock(title: "WHAT BROKE", text: evaluation.mainGap, color: .signalRed)
                    debriefBlock(title: "CORRECTION", text: evaluation.correction, color: .bone)
                    debriefBlock(title: "NEXT TARGET", text: evaluation.nextChallenge, color: .acid)
                }
                .padding(.top, 22)
            }
        case .offline:
            VStack(alignment: .leading, spacing: 14) {
                RBStatusChip(text: "ANALYSIS OFFLINE.", color: .acid, pulse: false)
                Text("TA SESSION EST SAUVEGARDÉE.")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundStyle(.bone)
                Text("Aucun score n'a été inventé. Réessaie quand la connexion revient.")
                    .font(.body(size: 14))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
                Button {
                    runAnalysis()
                } label: {
                    HStack {
                        Text("RETRY ANALYSIS")
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.rbSecondary())
                .padding(.top, 6)
            }
            .padding(.top, 26)
        }
    }

    private var sessionStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            RBEditorialDivider(label: "SESSION LOGGED")
                .padding(.top, 22)
            HStack {
                Text("DURÉE")
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(.ash)
                Spacer()
                Text("\(session.actualDurationSeconds / 60) MIN")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.bone)
            }
            if session.mode == .stay {
                HStack {
                    Text("SWITCHES")
                        .font(.metadata(size: 11))
                        .tracking(2)
                        .foregroundStyle(.ash)
                    Spacer()
                    Text("\(session.switchedCount)")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(session.switchedCount > 0 ? .signalRed : .signalCyan)
                }
            }
            Text("Session enregistrée. Elle compte pour le jour \(String(format: "%03d", session.protocolDay)) du protocole.")
                .font(.body(size: 13))
                .foregroundStyle(.ash)
                .lineSpacing(3)
                .padding(.top, 8)
        }
        .padding(.top, 4)
    }

    private func dimensionRail(_ evaluation: EvaluationResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(evaluation.dimensions) { dimension in
                if dimension.name != evaluation.dimensions.first?.name {
                    Rectangle()
                        .fill(Color.line)
                        .frame(height: 1)
                        .padding(.vertical, 10)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(dimension.name)
                        .font(.metadata(size: 11))
                        .tracking(2)
                        .foregroundStyle(.ash)
                    Spacer()
                    Text(String(format: "%.0f/10", dimension.score))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.signalCyan)
                }
                Text(dimension.reason)
                    .font(.body(size: 13))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    private func debriefBlock(title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(color)
                    .frame(width: 3, height: 18)
                Text(title)
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.body(size: 15))
                .foregroundStyle(.softBone)
                .lineSpacing(3)
        }
        .padding(.top, 18)
    }

    private var subjectiveSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBEditorialDivider(label: "SUBJECTIF")
                .padding(.top, 26)

            Text("CALME")
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)
                .padding(.top, 16)
            chipRow(value: $calm)

            Text("ÉNERGIE")
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)
                .padding(.top, 18)
            chipRow(value: $energy)

            if subjectiveSaved {
                Text("SAUVEGARDÉ")
                    .font(.metadata(size: 9))
                    .tracking(1.6)
                    .foregroundStyle(.signalCyan)
                    .padding(.top, 8)
            }
        }
        .onChange(of: calm) { _, _ in saveSubjective() }
        .onChange(of: energy) { _, _ in saveSubjective() }
    }

    private func chipRow(value: Binding<Int>) -> some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { n in
                Button {
                    value.wrappedValue = n
                    RBHaptics.play(.transition)
                } label: {
                    Text("\(n)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(value.wrappedValue == n ? .ink : .bone)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(value.wrappedValue == n ? Color.bone : Color.graphite)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private func saveSubjective() {
        session.calm = calm
        session.energy = energy
        modelContext.insert(SelfEvaluation(sessionID: session.id, calm: calm, energy: energy))
        subjectiveSaved = true
        try? modelContext.save()
    }

    private func runAnalysis() {
        session.analysisAttempted = true
        analysis = .analyzing
        let request = EvaluationContextBuilder.request(
            mode: session.mode,
            sourceContent: session.sourceContent,
            userResponse: session.userResponse,
            day: session.protocolDay,
            phase: session.phase,
            title: session.title
        )
        Task {
            do {
                let response = try await EvaluationService.provider.evaluate(request)
                let result = EvaluationResult(
                    sessionID: session.id,
                    overallScore: response.overallScore,
                    dimensions: response.dimensions,
                    strength: response.strength,
                    mainGap: response.mainGap,
                    correction: response.correction,
                    nextChallenge: response.nextChallenge,
                    confidence: response.confidence,
                    insufficientEvidence: response.insufficientEvidence,
                    followUpQuestion: response.followUpQuestion,
                    provider: "remote"
                )
                modelContext.insert(result)
                session.evaluation = result
                session.analysisOffline = false
                try? modelContext.save()
                withAnimation(.easeOut(duration: 0.3)) {
                    analysis = .success
                }
                RBHaptics.play(.transition)
            } catch {
                session.analysisOffline = true
                try? modelContext.save()
                withAnimation(.easeOut(duration: 0.3)) {
                    analysis = .offline
                }
            }
        }
    }
}
