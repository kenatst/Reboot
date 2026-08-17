import SwiftUI

/// NOTHING — low-stimulation practice. Not meditation, not a breathing circle.
struct VideSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var remaining: Int
    @State private var finished = false
    @State private var reflection = ""
    @State private var difference = ""
    @State private var timerTask: Task<Void, Never>?
    @State private var targetEndDate: Date
    @State private var isDimmed = false
    @State private var userInteracted = false

    init(session: TrainingSession, fastTimer: Bool = false, onComplete: @escaping (TrainingSession) -> Void) {
        self.session = session
        self.fastTimer = fastTimer
        self.onComplete = onComplete
        let total = session.plannedDurationSeconds
        self._remaining = State(initialValue: total)
        self._targetEndDate = State(initialValue: Date.now.addingTimeInterval(TimeInterval(total)))
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if !finished {
                silentPhase
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            userInteracted.toggle()
                        }
                    }
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && !finished {
                recalculateRemaining()
            }
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
            .padding(.top, 14)
            .opacity(isDimmed && !userInteracted ? 0.2 : 1)

            Spacer()

            Text("NO NEW\nSTIMULUS.")
                .font(.heroBlack(size: 40))
                .foregroundStyle(.bone)
                .multilineTextAlignment(.center)
                .opacity(isDimmed && !userInteracted ? 0.15 : 0.9)
                .animation(.easeInOut(duration: 2.0), value: isDimmed)

            RBTimerDisplay(seconds: remaining, size: 64, color: .ash, dimmed: true)
                .padding(.top, 30)
                .opacity(isDimmed && !userInteracted ? 0.35 : 0.9)

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
                    .font(.heroBlack(size: 36))
                    .foregroundStyle(.bone)
                    .padding(.top, 18)

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
                .padding(.bottom, 36)
            }
            .padding(.horizontal, RBSpacing.screen)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func recalculateRemaining() {
        if !fastTimer {
            let diff = Int(targetEndDate.timeIntervalSince(Date.now))
            remaining = max(0, diff)
            if remaining <= 0 {
                withAnimation(.easeInOut(duration: 0.4)) {
                    finished = true
                }
                RBHaptics.play(.transition)
            }
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        targetEndDate = Date.now.addingTimeInterval(TimeInterval(remaining))
        
        // Trigger soft dimming after 20 seconds
        Task {
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 2.0)) {
                    isDimmed = true
                }
            }
        }

        timerTask = Task {
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if fastTimer {
                    remaining -= 60
                } else {
                    recalculateRemaining()
                }
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
