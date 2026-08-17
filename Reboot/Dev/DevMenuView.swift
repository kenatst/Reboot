#if DEBUG
import SwiftUI
import SwiftData

/// DEBUG-only developer navigation. Never compiled into Release builds.
struct DevMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [RebootProgress]
    @Query private var sessions: [TrainingSession]

    @State private var mockEvaluation = DevState.mockEvaluation
    @State private var forceOffline = DevState.forceEvaluationOffline

    private var progress: RebootProgress? {
        progressList.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DEV NAVIGATION")
                .font(.metadata(size: 10))
                .tracking(2)
                .foregroundStyle(.acid)

            HStack(spacing: 8) {
                devButton("DAY 1") { setDay(1) }
                devButton("DAY 7") { setDay(7) }
                devButton("DAY 14") { setDay(14) }
                devButton("DAY 30") { setDay(30) }
                devButton("DAY 60") { setDay(60) }
                devButton("DAY 90") { setDay(90) }
            }
            .padding(.top, 10)

            HStack(spacing: 8) {
                devButton("EMPTY") { emptyState() }
                devButton("CALIBRATING") { setDay(2) }
                devButton("POPULATED") { populatedState() }
            }
            .padding(.top, 8)

            Toggle(isOn: $mockEvaluation) {
                Text("MOCK EVALUATION")
                    .font(.metadata(size: 10))
                    .tracking(1.4)
                    .foregroundStyle(.softBone)
            }
            .tint(.signalCyan)
            .padding(.top, 12)
            .onChange(of: mockEvaluation) { _, value in
                DevState.mockEvaluation = value
            }

            Toggle(isOn: $forceOffline) {
                Text("FORCE OFFLINE")
                    .font(.metadata(size: 10))
                    .tracking(1.4)
                    .foregroundStyle(.softBone)
            }
            .tint(.signalRed)
            .padding(.top, 6)
            .onChange(of: forceOffline) { _, value in
                DevState.forceEvaluationOffline = value
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.acid.opacity(0.45), lineWidth: 1)
        )
    }

    private func devButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.metadata(size: 9))
                .tracking(1)
                .foregroundStyle(.bone)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: RBRadius.sm)
                        .stroke(Color.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func setDay(_ day: Int) {
        DevDataFactory.setDay(day, progress: progress, context: modelContext)
    }

    private func emptyState() {
        DevDataFactory.empty(progress: progress, sessions: sessions, context: modelContext)
    }

    private func populatedState() {
        DevDataFactory.populate(progress: progress, sessions: sessions, context: modelContext)
    }
}
#endif
