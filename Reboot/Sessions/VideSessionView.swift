import SwiftUI

/// NOTHING — low-stimulation practice. Not meditation, not a breathing circle.
struct VideSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var remaining: Int
    @State private var finished = false
    @State private var reflection = ""
    @State private var difference = ""
    @State private var timerTask: Task<Void, Never>?

    init(session: TrainingSession, fastTimer: Bool = false, onComplete: @escaping (TrainingSession) -> Void) {
        self.session = session
        self.fastTimer = fastTimer
        self.onComplete = onComplete
        self._remaining = State(initialValue: session.plannedDurationSeconds)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if !finished {
                silentPhase
            } else {
                reflectionPhase
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timerTask?.cancel()
        }
        .overlay(alignment: .bottomTrailing) {
            #if DEBUG
            if UITestDriver.isActive, !finished {
                Button("DEBUG END") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        finished = true
                    }
                }
                .font(.metadata(size: 9))
                .foregroundStyle(.acid)
                .padding(.trailing, 12)
                .padding(.bottom, 90)
            }
            #endif
        }
        .statusBarHidden()
    }

    private var silentPhase: some View {
        VStack(spacing: 0) {
            HStack {
                RBSystemLabel(text: "PROTOCOL / NOTHING", color: .ash)
                Spacer()
                RBSystemLabel(text: "STATUS / SILENT", color: .ash)
            }
            .padding(.horizontal, RBSpacing.screen)
            .padding(.top, 12)

            Spacer()

            Text("NO NEW\nSTIMULUS.")
                .font(.heroBlack(size: 40))
                .foregroundStyle(.bone)
                .multilineTextAlignment(.center)
                .opacity(0.9)

            RBTimerDisplay(seconds: remaining, size: 64, color: .ash, dimmed: true)
                .padding(.top, 30)

            Spacer()
            Spacer()
        }
    }

    private var reflectionPhase: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RBSystemLabel(text: "PROTOCOL / NOTHING / COMPLETE", color: .signalCyan)
                    .padding(.top, 14)

                Text("QU'EST-CE QUI\nOCCUPAIT TON\nESPRIT ?")
                    .font(.heroBlack(size: 38))
                    .foregroundStyle(.bone)
                    .padding(.top, 20)

                Text("Rien à produire. Juste ce qui est apparu pendant que rien ne te nourrissait.")
                    .font(.body(size: 15))
                    .foregroundStyle(.ash)
                    .lineSpacing(4)
                    .padding(.top, 14)

                RBReconstructionEditor(
                    text: $reflection,
                    placeholder: "Ce qui occupait ton esprit…",
                    accent: .signalCyan
                )
                .padding(.top, 20)

                Text("Qu'est-ce qui est différent maintenant ?")
                    .font(.body(size: 15))
                    .foregroundStyle(.softBone)
                    .padding(.top, 20)

                RBReconstructionEditor(
                    text: $difference,
                    placeholder: "Facultatif…",
                    accent: .ash
                )
                .frame(minHeight: 110)
                .padding(.top, 12)

                Button {
                    finish()
                } label: {
                    HStack {
                        Text("TERMINER LA SESSION")
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
                .buttonStyle(.rbPrimary())
                .padding(.top, 26)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, RBSpacing.screen)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                remaining -= fastTimer ? 60 : 1
                if remaining <= 0 {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        finished = true
                    }
                    RBHaptics.play(.transition)
                }
            }
        }
    }

    private func finish() {
        session.userResponse = [reflection, difference]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")
        session.actualDurationSeconds = session.plannedDurationSeconds
        onComplete(session)
    }
}
