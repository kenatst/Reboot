import SwiftUI

/// EXPLAIN — learn, close it, teach it.
struct LearningSessionView: View {
    let session: TrainingSession
    var fastTimer = false
    var onComplete: (TrainingSession) -> Void

    @State private var reading = true
    @State private var transitioning = false
    @State private var response = ""

    private var module: LearningModule? {
        if let id = session.contentID {
            return ContentStore.learning(id: id)
        }
        let fallbackID = ContentSelector.select(context: ContentSelectionContext(mode: .explain, day: session.protocolDay)) ?? 1
        return ContentStore.learning(id: fallbackID)
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
            } else if transitioning {
                transitionScreen
                    .transition(.opacity)
            } else {
                teaching
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: RBMotion.standard), value: reading)
        .animation(.easeInOut(duration: RBMotion.standard), value: transitioning)
        .onAppear {
            #if DEBUG
            if fastTimer {
                Task {
                    try? await Task.sleep(nanoseconds: UITestDriver.holdReconstruction ? 6_000_000_000 : 2_000_000_000)
                    closeLesson()
                    try? await Task.sleep(nanoseconds: UITestDriver.holdReconstruction ? 6_000_000_000 : 1_000_000_000)
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
                        .fill(Color.ink.opacity(0.2))
                        .frame(height: 1)
                        .padding(.top, 16)

                    Text(text)
                        .font(.reading(size: 21))
                        .foregroundStyle(.ink)
                        .lineSpacing(9)
                        .padding(.top, 22)
                        .padding(.bottom, 24)

                    VStack(alignment: .center, spacing: 14) {
                        Rectangle()
                            .fill(Color.ink.opacity(0.15))
                            .frame(height: 1)

                        Text("FIN DE LA LEÇON")
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
                    closeLesson()
                } label: {
                    HStack {
                        Text("FERMER LA LEÇON")
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
                Text("LA LEÇON EST FERMÉE.")
                    .font(.heroBlack(size: 32))
                    .foregroundStyle(.bone)
                    .multilineTextAlignment(.center)
                RBSignalPulse(color: .signalCyan, diameter: 10)
            }
        }
    }

    private var teaching: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBSystemLabel(text: "EXPLAIN / RESTITUTION", color: .signalCyan)
                        .padding(.top, 14)

                    Text("ENSEIGNE-LE\nCOMME SI TU DEVAIS\nLE FAIRE COMPRENDRE.")
                        .font(.heroBlack(size: 34))
                        .foregroundStyle(.bone)
                        .lineSpacing(-3)
                        .padding(.top, 18)

                    Text(prompt)
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(4)
                        .padding(.top, 16)

                    RBReconstructionEditor(
                        text: $response,
                        placeholder: "Enseigne le principe, le mécanisme et un exemple…",
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

    private func closeLesson() {
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
