import SwiftUI
import SwiftData

/// Full-screen session lifecycle: setup → lock → active → debrief →
/// milestone/checkpoint. The tab bar is never visible during a session.
struct SessionFlowView: View {
    let request: SessionRequest
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [RebootProgress]

    enum Phase {
        case setup
        case locked
        case active
        case complete
        case debrief
        case overlay
    }

    @State private var phase: Phase = .setup
    @State private var activeSession: TrainingSession?
    @State private var overlay: SessionOverlay?
    @State private var showMilestone = false
    @State private var autoStarted = false

    enum SessionOverlay: Identifiable {
        case checkpoint(week: Int)
        case milestone(Milestone)
        case phaseIntro(phase: Int)

        var id: String {
            switch self {
            case .checkpoint(let week): return "cp\(week)"
            case .milestone(let m): return m.rawValue
            case .phaseIntro(let phase): return "pi\(phase)"
            }
        }
    }

    private var progress: RebootProgress? {
        progressList.first
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            switch phase {
            case .setup:
                SessionSetupView(request: request) { lockedRequest in
                    begin(lockedRequest)
                }
            case .locked:
                RBLockScreen(title: "LOCK THIS SESSION.", subtitle: request.mode.label)
                    .transition(.opacity)
            case .active:
                activeView
                    .transition(.opacity)
            case .complete:
                RBLockScreen(title: "SESSION COMPLETE.", subtitle: "PROTOCOL / DAY \(String(format: "%03d", request.day))")
                    .transition(.opacity)
            case .debrief:
                if let session = activeSession {
                    SessionDebriefView(session: session) {
                        handleAfterDebrief()
                    }
                }
            case .overlay:
                Color.void.ignoresSafeArea()
            }
            overlayLayer
        }
        .animation(.easeInOut(duration: RBMotion.slow), value: phase == .locked)
        .onAppear {
            guard request.skipSetup, !autoStarted else { return }
            autoStarted = true
            begin(request)
        }
    }

    @ViewBuilder
    private var activeView: some View {
        if let session = activeSession {
            switch session.mode {
            case .stay:
                StaySessionView(session: session, fastTimer: request.fastTimer, onComplete: complete)
            case .recall:
                ReadingSessionView(session: session, fastTimer: request.fastTimer, onComplete: complete)
            case .explain:
                LearningSessionView(session: session, fastTimer: request.fastTimer, onComplete: complete)
            case .nothing:
                VideSessionView(session: session, fastTimer: request.fastTimer, onComplete: complete)
            case .observe:
                ObserveSessionView(session: session, fastTimer: request.fastTimer, onComplete: complete)
            }
        }
    }

    @ViewBuilder
    private var overlayLayer: some View {
        if let overlay {
            ZStack {
                switch overlay {
                case .phaseIntro(let phase):
                    PhaseIntroView(phase: phase) {
                        self.overlay = nil
                        dismissAll()
                    }
                case .checkpoint(let week):
                    CheckpointView(week: week) {
                        self.overlay = nil
                        dismissAll()
                    }
                case .milestone(let milestone):
                    MilestoneView(milestone: milestone) {
                        self.overlay = nil
                        dismissAll()
                    }
                }
            }
            .transition(.opacity)
            .zIndex(10)
        }
    }

    private func begin(_ lockedRequest: SessionRequest) {
        let plan = ProtocolCurriculum.day(lockedRequest.day)
        let session = TrainingSession(
            protocolDay: lockedRequest.day,
            phase: plan.phase,
            mode: lockedRequest.mode,
            title: lockedRequest.title,
            intention: plan.intention,
            plannedDurationSeconds: lockedRequest.duration * 60,
            completionOrdinal: (progress?.completedSessions ?? 0) + 1
        )
        modelContext.insert(session)
        activeSession = session
        RBHaptics.play(.lock)
        if lockedRequest.skipSetup {
            withAnimation(.easeOut(duration: 0.3)) {
                phase = .active
            }
        } else {
            withAnimation(RBMotion.lock) {
                phase = .locked
            }
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = .active
                }
            }
        }
    }

    private func complete(session: TrainingSession) {
        if session.actualDurationSeconds <= 0 {
            session.actualDurationSeconds = max(1, Int(Date.now.timeIntervalSince(session.date)))
        }
        session.date = .now
        try? modelContext.save()
        advanceProgress()
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .complete
        }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                phase = .debrief
            }
        }
    }

    private func advanceProgress() {
        guard let progress else { return }
        let before = progress.completedSessions
        let beforePhase = ProtocolEngine.phaseNumber(forDay: min(90, before + 1))
        progress.completedSessions += 1
        progress.currentDay = min(90, progress.completedSessions + 1)
        progress.lastSessionDate = .now
        if progress.completedSessions >= 90 {
            progress.coreModeUnlocked = true
        }
        modelContext.insert(
            ProtocolDayCompletion(
                dayNumber: min(90, progress.completedSessions),
                sessionID: activeSession?.id ?? UUID()
            )
        )
        let status = ProtocolEngine.clarityStatus(sessionsCompleted: progress.completedSessions).label
        modelContext.insert(ClaritySnapshot(completedSessions: progress.completedSessions, statusRaw: status))

        let afterPhase = ProtocolEngine.phaseNumber(forDay: progress.completedSessions)
        if afterPhase > beforePhase, afterPhase >= 2, afterPhase <= 4 {
            overlay = .phaseIntro(phase: afterPhase)
        } else if let week = ProtocolEngine.checkpointDue(completedBefore: before, completedAfter: progress.completedSessions) {
            overlay = .checkpoint(week: week)
        } else if let milestone = ProtocolEngine.milestoneReached(completedBefore: before, completedAfter: progress.completedSessions) {
            overlay = .milestone(milestone)
        }
        try? modelContext.save()
    }

    private func handleAfterDebrief() {
        if overlay != nil {
            phase = .overlay
        } else {
            dismissAll()
        }
    }

    private func dismissAll() {
        dismiss()
    }
}
