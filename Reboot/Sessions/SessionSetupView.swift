import SwiftUI

struct SessionSetupView: View {
    let request: SessionRequest
    var onLock: (SessionRequest) -> Void

    @State private var task = ""
    @State private var duration: Int
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
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RBProtocolHeader(day: request.day, phase: plan.phase)
                        .padding(.top, 8)

                    Text("PROTOCOL / \(request.mode.label)")
                        .font(.metadata(size: 11))
                        .tracking(2)
                        .foregroundStyle(accent)
                        .padding(.top, 34)

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
                            Text("TÂCHE")
                                .font(.metadata(size: 11))
                                .tracking(2)
                                .foregroundStyle(.ash)
                            TextField("Une seule chose à faire", text: $task)
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
                        .padding(.top, 26)
                    }

                    Text("DURÉE")
                        .font(.metadata(size: 11))
                        .tracking(2)
                        .foregroundStyle(.ash)
                        .padding(.top, 26)
                    HStack(spacing: 10) {
                        ForEach(durations, id: \.self) { d in
                            Button {
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

                    RBEditorialDivider(label: "PROTOCOL")
                        .padding(.top, 30)

                    Text(plan.intention)
                        .font(.body(size: 16))
                        .foregroundStyle(.softBone)
                        .lineSpacing(3)
                        .padding(.top, 16)

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
                    .padding(.top, 16)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.acid)
                        Text(plan.optionalChallenge)
                            .font(.body(size: 13))
                            .foregroundStyle(.softBone)
                            .lineSpacing(3)
                    }
                    .padding(.top, 16)

                    Button {
                        taskFocused = false
                        var locked = request
                        if request.mode == .stay {
                            locked = SessionRequest(
                                mode: request.mode,
                                day: request.day,
                                duration: duration,
                                title: task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? request.title : task,
                                contentID: request.contentID
                            )
                        } else {
                            locked = SessionRequest(
                                mode: request.mode,
                                day: request.day,
                                duration: duration,
                                title: request.title,
                                contentID: request.contentID
                            )
                        }
                        onLock(locked)
                    } label: {
                        HStack {
                            Text("LOCK THIS SESSION.")
                            Spacer()
                            Image(systemName: "lock.fill")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, 30)
                    .padding(.bottom, max(20, geo.safeAreaInsets.bottom + 12))
                }
                .padding(.horizontal, RBSpacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
        }
        .background(Color.void.ignoresSafeArea())
    }

    private var accent: Color {
        request.day <= 14 ? .signalRed : .signalCyan
    }
}
