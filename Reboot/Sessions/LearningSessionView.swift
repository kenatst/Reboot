import SwiftUI

/// EXPLAIN — learn, close it, teach it.
struct LearningSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var reading = true
    @State private var response = ""

    private var module: LearningModule? {
        ContentStore.learning(id: ((session.protocolDay - 1) % 35) + 1)
    }

    private var text: String {
        module?.text ?? "Module indisponible. Ferme la leçon et enseigne ce que tu retiens."
    }

    private var prompt: String {
        module?.teachBackPrompt ?? "Explique la leçon comme à quelqu'un qui n'y connaît rien."
    }

    var body: some View {
        ZStack {
            if reading {
                reader
                    .transition(.opacity)
            } else {
                teaching
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
                    response = "Ce que j'enseigne : la mémoire de travail est une scène étroite, et tout ce qui entre en compétition la dégrade. L'exemple du téléphone montre que la distraction n'est pas une invasion mais une transaction. En pratique, je ferme les fenêtres avant de commencer, et je note les intrusions pour les voir."
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
                        RBSystemLabel(text: "EXPLAIN / \(module?.topic.uppercased() ?? "LEARNING")", color: .ink.opacity(0.55))
                        Spacer()
                        if let module {
                            Text("\(module.wordCount) MOTS · \(module.readingMinutes) MIN")
                                .font(.metadata(size: 10))
                                .tracking(1)
                                .foregroundStyle(.ink.opacity(0.55))
                        }
                    }
                    .padding(.top, 14)

                    Text(module?.title ?? "APPRENTISSAGE")
                        .font(.heroBlack(size: 32))
                        .tracking(-0.4)
                        .foregroundStyle(.ink)
                        .padding(.top, 20)

                    Rectangle()
                        .fill(Color.ink.opacity(0.25))
                        .frame(height: 1)
                        .padding(.top, 16)

                    Text(text)
                        .font(.reading(size: 19))
                        .foregroundStyle(.ink)
                        .lineSpacing(8)
                        .padding(.top, 22)
                        .padding(.bottom, 30)
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
                        Text("LESSON CLOSED. TEACH IT.")
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

    private var teaching: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBSystemLabel(text: "EXPLAIN / LESSON CLOSED", color: .signalCyan)
                        .padding(.top, 14)

                    Text("ENSEIGNE\nLA LEÇON.")
                        .font(.heroBlack(size: 42))
                        .foregroundStyle(.bone)
                        .padding(.top, 20)

                    Text("\(prompt)\n\nAucun minimum de mots. Ce que tu peux enseigner est ce que tu as compris.")
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(4)
                        .padding(.top, 18)

                    RBReconstructionEditor(
                        text: $response,
                        placeholder: "Enseigne-la comme à quelqu'un qui n'y connaît rien…",
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
