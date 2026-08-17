import SwiftUI

/// RECALL — active reading, then reconstruction from memory.
struct ReadingSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var reading = true
    @State private var transitioning = false
    @State private var response = ""
    @State private var scrollOffset: CGFloat = 0

    private var exercise: ReadingExercise? {
        let id = ((session.protocolDay - 1) % 60) + 1
        return session.task.isEmpty ? ContentStore.reading(id: id) : nil
    }

    private var text: String {
        exercise?.text ?? "Texte indisponible. Ferme le texte et reconstruis ce que tu retiens de ta lecture."
    }

    private var question: String {
        exercise?.question ?? "Qu'est-ce qui est réellement resté ?"
    }

    var body: some View {
        ZStack {
            if reading {
                reader
                    .transition(.opacity)
            } else if transitioning {
                transitionScreen
                    .transition(.opacity)
            } else {
                reconstruction
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: RBMotion.standard), value: reading)
        .animation(.easeInOut(duration: RBMotion.standard), value: transitioning)
        .onAppear {
            #if DEBUG
            if fastTimer {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    closeText()
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    response = "Je retiens l'idée centrale : l'attention se reconstruit par la répétition du retour. L'exemple du texte montre que rester sur une chose change la qualité de la compréhension. La leçon que j'en tire : fermer les concurrents avant de commencer."
                    finish()
                }
            }
            #endif
        }
        .statusBarHidden()
    }

    private var reader: some View {
        ZStack {
            Color.bone.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        RBSystemLabel(
                            text: exercise.map { "\($0.category) / \($0.length.label)" } ?? "RECALL",
                            color: .ink.opacity(0.55)
                        )
                        Spacer()
                        if let exercise {
                            Text("\(exercise.wordCount) MOTS · \(exercise.readingMinutes) MIN")
                                .font(.metadata(size: 10))
                                .tracking(1)
                                .foregroundStyle(.ink.opacity(0.55))
                        }
                    }
                    .padding(.top, 14)

                    Text(exercise?.title ?? "LECTURE ACTIVE")
                        .font(.heroBlack(size: 34))
                        .tracking(-0.4)
                        .foregroundStyle(.ink)
                        .padding(.top, 20)

                    Rectangle()
                        .fill(Color.ink.opacity(0.2))
                        .frame(height: 1)
                        .padding(.top, 16)

                    Text(text)
                        .font(.reading(size: 21))
                        .foregroundStyle(.ink)
                        .lineSpacing(9)
                        .padding(.top, 24)
                        .padding(.bottom, 24)

                    // Dedicated finish mark at the end of the text
                    VStack(alignment: .center, spacing: 14) {
                        Rectangle()
                            .fill(Color.ink.opacity(0.15))
                            .frame(height: 1)

                        Text("FIN DU TEXTE")
                            .font(.metadata(size: 11))
                            .tracking(2)
                            .foregroundStyle(.ink.opacity(0.45))
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 26)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.ink.opacity(0.12))
                    .frame(height: 1)

                Button {
                    closeText()
                } label: {
                    HStack {
                        Text("FERMER LE TEXTE")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.rbPrimary(scheme: .light))
                .padding(.horizontal, RBSpacing.screen)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
            .background(Color.bone)
        }
    }

    private var transitionScreen: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("LE TEXTE EST FERMÉ.")
                    .font(.heroBlack(size: 32))
                    .foregroundStyle(.bone)
                    .multilineTextAlignment(.center)
                RBSignalPulse(color: .signalCyan, diameter: 10)
            }
        }
    }

    private var reconstruction: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBSystemLabel(text: "RECALL / RECONSTRUCTION", color: .signalCyan)
                        .padding(.top, 14)

                    Text("QU'EST-CE QUI\nRESTE ?")
                        .font(.heroBlack(size: 40))
                        .foregroundStyle(.bone)
                        .padding(.top, 18)

                    Text(question)
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(4)
                        .padding(.top, 16)

                    RBReconstructionEditor(
                        text: $response,
                        placeholder: "Reconstruis l'argument central sans notes…",
                        accent: .signalCyan
                    )
                    .padding(.top, 20)

                    Button {
                        finish()
                    } label: {
                        HStack {
                            Text("ANALYSER MA RESTITUTION")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func closeText() {
        RBHaptics.play(.lock)
        withAnimation(.easeInOut(duration: 0.25)) {
            reading = false
            transitioning = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                transitioning = false
            }
        }
    }

    private func finish() {
        session.userResponse = response
        session.sourceContent = text
        session.actualDurationSeconds = max(1, Int(Date.now.timeIntervalSince(session.date)))
        onComplete(session)
    }
}
