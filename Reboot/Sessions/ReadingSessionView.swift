import SwiftUI

/// RECALL — active reading, then reconstruction from memory.
struct ReadingSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var reading = true
    @State private var response = ""

    private var exercise: ReadingExercise? {
        let id = ((session.protocolDay - 1) % 50) + 1
        return session.task.isEmpty ? ContentStore.reading(id: id) : nil
    }

    private var text: String {
        exercise?.text ?? "Texte indisponible. Ferme le texte et reconstruis ce que tu retiens de ta journée."
    }

    private var question: String {
        exercise?.question ?? "Qu'est-ce qui est réellement resté ?"
    }

    var body: some View {
        ZStack {
            if reading {
                reader
                    .transition(.opacity)
            } else {
                reconstruction
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: reading)
        .onAppear {
            #if DEBUG
            if fastTimer {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if reading {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            reading = false
                        }
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
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
                        .padding(.top, 22)

                    Rectangle()
                        .fill(Color.ink.opacity(0.25))
                        .frame(height: 1)
                        .padding(.top, 18)

                    Text(text)
                        .font(.reading(size: 19))
                        .foregroundStyle(.ink)
                        .lineSpacing(8)
                        .padding(.top, 24)
                        .padding(.bottom, 30)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 26)
            }

            VStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        reading = false
                    }
                    RBHaptics.play(.lock)
                } label: {
                    HStack {
                        Text("CLOSE THE TEXT")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.rbPrimary(scheme: .light))
                .padding(.horizontal, RBSpacing.screen)
                .padding(.bottom, 18)
            }
        }
    }

    private var reconstruction: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBSystemLabel(text: "RECALL / THE TEXT IS GONE", color: .signalCyan)
                        .padding(.top, 14)

                    Text("LE TEXTE\nEST FERMÉ.")
                        .font(.heroBlack(size: 42))
                        .foregroundStyle(.bone)
                        .padding(.top, 20)

                    Text("\(question)\n\nAucun minimum de mots. Ce qui est resté est ce qui compte.")
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(4)
                        .padding(.top, 18)

                    RBReconstructionEditor(
                        text: $response,
                        placeholder: "Reconstruis ce qui est resté…",
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
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func finish() {
        session.userResponse = response
        session.sourceContent = text
        session.actualDurationSeconds = max(1, Int(Date.now.timeIntervalSince(session.date)))
        onComplete(session)
    }
}
