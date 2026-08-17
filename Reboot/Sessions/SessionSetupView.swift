import SwiftUI

struct SessionSetupView: View {
    let request: SessionRequest
    var onLock: (SessionRequest) -> Void

    @State private var task = ""
    @State private var duration: Int
    @State private var showingCommit = false
    @FocusState private var taskFocused: Bool

    init(request: SessionRequest, onLock: @escaping (SessionRequest) -> Void) {
        self.request = request
        self.onLock = onLock
        self._duration = State(initialValue: request.duration)
    }

    private var plan: ProtocolDay {
        ProtocolCurriculum.day(request.day)
    }

    private var durations: [Int] {
        ProtocolEngine.suggestedDurations(for: request.mode, day: request.day)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.void.ignoresSafeArea()
                if showingCommit && request.mode == .stay {
                    commitView(geo: geo)
                        .transition(.opacity)
                } else {
                    setupView(geo: geo)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: RBMotion.standard), value: showingCommit)
        }
        .background(Color.void.ignoresSafeArea())
    }

    private func setupView(geo: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RBProtocolHeader(day: request.day, phase: plan.phase)
                    .padding(.top, 10)

                Text("PROTOCOL / \(request.mode.label)")
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(accent)
                    .padding(.top, 30)

                Text(request.mode.frenchLabel)
                    .font(.system(size: 34, weight: .black, design: .default))
                    .foregroundStyle(.bone)
                    .padding(.top, 8)

                Text(request.mode.tagline)
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(.ash)
                    .lineSpacing(3)
                    .padding(.top, 12)

                if request.mode == .stay {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TÂCHE UNIQUE")
                            .font(.metadata(size: 11))
                            .tracking(2)
                            .foregroundStyle(.ash)
                        TextField("Nomme la seule chose à faire…", text: $task)
                            .font(.system(size: 17, weight: .semibold, design: .default))
                            .foregroundStyle(.bone)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: RBRadius.sm)
                                    .stroke(taskFocused ? accent : Color.line, lineWidth: 1)
                            )
                            .focused($taskFocused)
                    }
                    .padding(.top, 24)
                }

                Text("DURÉE")
                    .font(.metadata(size: 11))
                    .tracking(2)
                    .foregroundStyle(.ash)
                    .padding(.top, 24)

                HStack(spacing: 10) {
                    ForEach(durations, id: \.self) { d in
                        Button {
                            RBHaptics.play(.selection)
                            withAnimation(.easeOut(duration: 0.16)) {
                                duration = d
                            }
                        } label: {
                            Text("\(d)")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(duration == d ? .ink : .bone)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(duration == d ? Color.bone : Color.graphite)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 10)

                Text("\(request.mode.frenchLabel) — \(duration) MIN")
                    .font(.metadata(size: 10))
                    .tracking(1.2)
                    .foregroundStyle(.ash.opacity(0.85))
                    .padding(.top, 10)

                RBEditorialDivider(label: "PROTOCOLE DU JOUR")
                    .padding(.top, 26)

                Text(plan.intention)
                    .font(.body(size: 16))
                    .foregroundStyle(.softBone)
                    .lineSpacing(3)
                    .padding(.top, 14)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(plan.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text(String(format: "%02d", index + 1))
                                .font(.metadata(size: 11))
                                .foregroundStyle(accent)
                            Text(instruction)
                                .font(.body(size: 14))
                                .foregroundStyle(.bone)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(.top, 14)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.acid)
                    Text(plan.optionalChallenge)
                        .font(.body(size: 13))
                        .foregroundStyle(.softBone)
                        .lineSpacing(3)
                }
                .padding(.top, 14)

                Button {
                    taskFocused = false
                    if request.mode == .stay {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingCommit = true
                        }
                    } else {
                        commitAndLock()
                    }
                } label: {
                    HStack {
                        Text(request.mode == .stay ? "CONTINUER" : "VERROUILLER LA SESSION")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.rbPrimary())
                .padding(.top, 28)
                .padding(.bottom, max(24, geo.safeAreaInsets.bottom + 16))
            }
            .padding(.horizontal, RBSpacing.screen)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func commitView(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RBSystemLabel(text: "PROTOCOL / COMMIT", color: .signalCyan)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingCommit = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.ash)
                }
            }
            .padding(.top, 14)

            Spacer()

            Text("TA TÂCHE UNIQUE :")
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)

            Text(task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "TRAVAIL PROFOND" : task)
                .font(.system(size: 28, weight: .heavy, design: .default))
                .foregroundStyle(.bone)
                .padding(.top, 10)

            Text("\(duration) MINUTES")
                .font(.heroBlack(size: 44))
                .foregroundStyle(.signalCyan)
                .padding(.top, 16)

            Text("Pendant \(duration) minutes, cette tâche est la seule tâche.\nTous les autres onglets et notifications sont fermés.")
                .font(.body(size: 16))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
                .padding(.top, 16)

            Spacer()

            Button {
                commitAndLock()
            } label: {
                HStack {
                    Text("VERROUILLER LA SESSION →")
                    Spacer()
                    Image(systemName: "lock.fill")
                }
            }
            .buttonStyle(.rbPrimary())
            .padding(.bottom, max(24, geo.safeAreaInsets.bottom + 16))
        }
        .padding(.horizontal, RBSpacing.screen)
    }

    private func commitAndLock() {
        let finalTask = task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? request.title : task
        let locked = SessionRequest(
            mode: request.mode,
            day: request.day,
            duration: duration,
            title: finalTask,
            contentID: request.contentID
        )
        onLock(locked)
    }

    private var accent: Color {
        request.day <= 14 ? .signalRed : .signalCyan
    }
}
