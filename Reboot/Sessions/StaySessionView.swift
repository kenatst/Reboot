import SwiftUI

/// CONCENTRATION — a single task, nothing else.
struct StaySessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var remaining: Int
    @State private var paused = false
    @State private var switchNotice = false
    @State private var task: String
    @State private var timerTask: Task<Void, Never>?
    @State private var finished = false

    init(session: TrainingSession, fastTimer: Bool = false, onComplete: @escaping (TrainingSession) -> Void) {
        self.session = session
        self.fastTimer = fastTimer
        self.onComplete = onComplete
        self._remaining = State(initialValue: session.plannedDurationSeconds)
        self._task = State(initialValue: session.task.isEmpty ? session.title : session.task)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    RBSystemLabel(text: "PROTOCOL / STAY", color: .signalCyan)
                    Spacer()
                    RBSystemLabel(text: "STATUS / \(paused ? "PAUSED" : "ACTIVE")", color: paused ? .acid : .signalCyan)
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.top, 12)

                Spacer()

                Text(task)
                    .font(.system(size: 19, weight: .bold, design: .default))
                    .foregroundStyle(.softBone)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RBSpacing.screen)

                RBTimerDisplay(seconds: remaining, size: 78)
                    .padding(.top, 22)
                    .padding(.bottom, 18)

                RBSignalLine(color: .signalCyan, thickness: 2, draws: !paused)
                    .frame(width: 96)
                    .opacity(switchNotice ? 0 : 1)

                if switchNotice {
                    VStack(spacing: 4) {
                        Text("SWITCH REGISTERED.")
                            .font(.metadata(size: 12))
                            .tracking(2)
                            .foregroundStyle(.signalRed)
                        Text("RETURN.")
                            .font(.metadata(size: 12))
                            .tracking(2)
                            .foregroundStyle(.bone)
                    }
                    .padding(.top, 12)
                }

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        togglePause()
                    } label: {
                        Text(paused ? "REPRENDRE" : "PAUSE")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .tracking(1.4)
                            .foregroundStyle(.bone)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: RBRadius.sm)
                                    .stroke(Color.bone.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        registerSwitch()
                    } label: {
                        Text("I SWITCHED")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .tracking(1.4)
                            .foregroundStyle(.signalRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: RBRadius.sm)
                                    .stroke(Color.signalRed.opacity(0.55), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, 30)
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
            if UITestDriver.isActive {
                Button("DEBUG END") {
                    finish()
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

    private func startTimer() {
        timerTask?.cancel()
        guard !finished else { return }
        timerTask = Task {
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if paused { continue }
                remaining -= fastTimer ? 60 : 1
                if remaining <= 0 {
                    finish()
                }
            }
        }
    }

    private func togglePause() {
        paused.toggle()
        if !paused {
            startTimer()
        }
        RBHaptics.play(.transition)
    }

    private func registerSwitch() {
        session.switchedCount += 1
        RBHaptics.play(.interruption)
        switchNotice = true
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                switchNotice = false
            }
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        timerTask?.cancel()
        session.actualDurationSeconds = session.plannedDurationSeconds
        session.task = task
        onComplete(session)
    }
}
