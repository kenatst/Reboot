import SwiftUI

/// OBSERVE — analytical walk. Look before you scroll.
struct ObserveSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var showingReflection = false
    @State private var reflection = ""
    @State private var elapsed = 0
    @State private var timerTask: Task<Void, Never>?

    private var mission: ObservationMission? {
        ContentStore.mission(id: ((session.protocolDay - 1) % 35) + 1)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if !showingReflection {
                missionPhase
            } else {
                reflectionPhase
            }
        }
        .onAppear {
            startClock()
        }
        .onDisappear {
            timerTask?.cancel()
        }
        .overlay(alignment: .bottomTrailing) {
            #if DEBUG
            if UITestDriver.isActive, !showingReflection {
                Button("DEBUG NEXT") {
                    timerTask?.cancel()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingReflection = true
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

    private var missionPhase: some View {
        VStack(spacing: 0) {
            HStack {
                RBSystemLabel(text: "PROTOCOL / OBSERVE", color: .signalRed)
                Spacer()
                Text(String(format: "%02d:%02d", elapsed / 60, elapsed % 60))
                    .font(.metadata(size: 12))
                    .foregroundStyle(.ash)
                    .monospacedDigit()
            }
            .padding(.horizontal, RBSpacing.screen)
            .padding(.top, 12)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("MISSION \(String(format: "%03d", mission?.id ?? session.protocolDay))")
                    .font(.metadata(size: 12))
                    .tracking(2)
                    .foregroundStyle(.signalRed)

                Text(mission?.mission ?? "Observe sans téléphone. Regarde avant de scroller.")
                    .font(.system(size: 30, weight: .black, design: .default))
                    .foregroundStyle(.bone)
                    .lineSpacing(2)
                    .padding(.top, 16)

                if let cues = mission?.cues, !cues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(cues.enumerated()), id: \.offset) { index, cue in
                            HStack(alignment: .top, spacing: 10) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.metadata(size: 10))
                                    .foregroundStyle(.ash)
                                Text(cue)
                                    .font(.body(size: 14))
                                    .foregroundStyle(.softBone)
                                    .lineSpacing(3)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal, RBSpacing.screen)

            Spacer()

            Button {
                timerTask?.cancel()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingReflection = true
                }
            } label: {
                HStack {
                    Text("RÉFLÉCHIR")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.rbPrimary())
            .padding(.horizontal, RBSpacing.screen)
            .padding(.bottom, 26)
        }
    }

    private var reflectionPhase: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RBSystemLabel(text: "OBSERVE / REFLECTION", color: .signalCyan)
                    .padding(.top, 14)

                Text(mission?.reflection ?? "Qu'est-ce que tu as vu que tu n'aurais pas vu en scrollant ?")
                    .font(.heroBlack(size: 34))
                    .foregroundStyle(.bone)
                    .padding(.top, 18)

                RBReconstructionEditor(
                    text: $reflection,
                    placeholder: "Ce que ton regard a attrapé…",
                    accent: .signalCyan
                )
                .padding(.top, 22)

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

    private func startClock() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if !showingReflection {
                    elapsed += fastTimer ? 60 : 1
                }
            }
        }
    }

    private func finish() {
        session.userResponse = reflection
        session.sourceContent = mission?.mission ?? ""
        session.actualDurationSeconds = max(60, elapsed)
        onComplete(session)
    }
}
