import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [RebootProgress]
    @State private var onboardingCompleted = PreferencesStore.shared.onboardingCompleted
    @State private var showOnboarding = false
    @State private var onboardingPage = 0
    @State private var selectedTab = 0
    @State private var testSession: SessionRequest?
    @State private var testMilestone: Milestone?
    @State private var showSettings = false
    @State private var showProgram = false
    @State private var showDiagnosis = false
    @State private var showExplore: SessionMode?
    @State private var showFlowLabDirect = false
    @State private var flowSessionProject: FlowProject?
    @State private var showExperimentsDirect = false
    @State private var showCheckpointDirect = false
    @State private var showPhaseIntroDirect = false

    private var progress: RebootProgress? {
        progressList.first
    }

    var body: some View {
        Group {
            if onboardingCompleted {
                MainTabsView(initialSelection: initialTab)
            } else {
                Color.void.ignoresSafeArea()
            }
        }
        .onAppear {
            ensureProgressExists()
            #if DEBUG
            let results = EngineTests.run()
            for r in results {
                print("🧪 [ENGINE_TEST] \(r)")
            }
            if UITestDriver.isActive {
                configureForUITest()
            }
            #endif
            let completed = PreferencesStore.shared.onboardingCompleted
            let shownBefore = PreferencesStore.shared.onboardingShownAtLeastOnce
            if !completed && !shownBefore {
                PreferencesStore.shared.onboardingShownAtLeastOnce = true
                #if DEBUG
                onboardingPage = UITestDriver.isActive ? UITestDriver.initialOnboardingPage : 0
                #endif
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(initialPage: onboardingPage) { commit in
                PreferencesStore.shared.onboardingCompleted = true
                onboardingCompleted = true
                showOnboarding = false
                if commit {
                    RBHaptics.play(.lock)
                    let profile = AdaptiveRebootEngineDriver.ensureProfile(context: modelContext)
                    if !profile.isCalibrated {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            showDiagnosis = true
                        }
                    } else {
                        AdaptiveRebootEngineDriver.generatePrescription(forDay: 1, context: modelContext)
                    }
                }
            }
            .interactiveDismissDisabled(true)
            .onDisappear {
                // Safety: any dismissal path completes onboarding so the app
                // never returns to the intro after a cover closes.
                PreferencesStore.shared.onboardingCompleted = true
                onboardingCompleted = true
            }
        }
        .fullScreenCover(item: $testSession) { request in
            SessionFlowView(request: request)
        }
        .fullScreenCover(item: $testMilestone) { milestone in
            MilestoneView(milestone: milestone) {
                testMilestone = nil
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .fullScreenCover(isPresented: $showProgram) {
            NavigationStack {
                ProgramView()
            }
        }
        .fullScreenCover(isPresented: $showDiagnosis) {
            OnboardingDiagnosisView()
        }
        .sheet(item: $showExplore) { mode in
            ExploreLibraryView(mode: mode)
        }
        .fullScreenCover(isPresented: $showFlowLabDirect) {
            FlowLabView()
        }
        .fullScreenCover(item: $flowSessionProject) { project in
            FlowSessionView(project: project)
        }
        .fullScreenCover(isPresented: $showExperimentsDirect) {
            ExperimentsView()
        }
        .fullScreenCover(isPresented: $showCheckpointDirect) {
            CheckpointView(week: 1) {
                showCheckpointDirect = false
            }
        }
        .fullScreenCover(isPresented: $showPhaseIntroDirect) {
            PhaseIntroView(phase: 2) {
                showPhaseIntroDirect = false
            }
        }
        .preferredColorScheme(preferredScheme)
        .tint(.signalCyan)
        .onReceive(NotificationCenter.default.publisher(for: .rebootShowOnboarding)) { _ in
            onboardingCompleted = false
            showOnboarding = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .rebootPreferencesChanged)) { _ in
            // Force view refresh when appearance / preferences change.
            onboardingCompleted = PreferencesStore.shared.onboardingCompleted
        }
    }

    private var preferredScheme: ColorScheme? {
        switch PreferencesStore.shared.appearance {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    private func ensureProgressExists() {
        if progressList.isEmpty {
            modelContext.insert(RebootProgress())
            try? modelContext.save()
        }
    }

    #if DEBUG
    private static var didConfigureUITest = false

    private func configureForUITest() {
        guard !Self.didConfigureUITest else { return }
        Self.didConfigureUITest = true
        DevState.mockEvaluation = UITestDriver.mockEval
        DevState.forceEvaluationOffline = UITestDriver.forceOffline
        #if DEBUG
        if UITestDriver.autoTour {
            // Profile injection happens at tour start (MainTabsView), so the
            // recording shows the calibration flow first.
            DevState.mockEvaluation = true
        }
        #endif
        if UITestDriver.resetOnboarding {
            PreferencesStore.shared.onboardingCompleted = false
            onboardingCompleted = false
        }
        if UITestDriver.skipOnboarding || UITestDriver.autoFinishOnboarding {
            PreferencesStore.shared.onboardingCompleted = true
            onboardingCompleted = true
        }
        if let day = UITestDriver.setDay, let progress = progressList.first {
            DevDataFactory.setDay(day, progress: progress, context: modelContext)
        }
        if UITestDriver.populated {
            DevDataFactory.populate(
                progress: progressList.first,
                sessions: (try? modelContext.fetch(FetchDescriptor<TrainingSession>())) ?? [],
                context: modelContext
            )
        }
        if let raw = UITestDriver.sessionMode, let mode = SessionMode(rawValue: raw) {
            let request = SessionRequest(
                mode: mode,
                day: UITestDriver.sessionDay,
                duration: UITestDriver.sessionDuration,
                title: ProtocolCurriculum.day(UITestDriver.sessionDay).title,
                contentID: ProtocolCurriculum.day(UITestDriver.sessionDay).contentID,
                skipSetup: !UITestDriver.sessionSetup,
                fastTimer: UITestDriver.fastTimer
            )
            testSession = request
        }
        if UITestDriver.settings {
            showSettings = true
        }
        if UITestDriver.program {
            showProgram = true
        }
        if let raw = UITestDriver.exploreMode, let mode = SessionMode(rawValue: raw) {
            showExplore = mode
        }
        if UITestDriver.flowLab {
            showFlowLabDirect = true
        }
        if UITestDriver.flowSession {
            let project = FlowProject(title: "Préparer la présentation client", definitionOfDone: "Slides 1–5 finalisées", feedbackType: "slides")
            modelContext.insert(project)
            try? modelContext.save()
            flowSessionProject = project
        }
        if UITestDriver.experimentsDirect {
            showExperimentsDirect = true
        }
        if UITestDriver.checkpointDirect {
            showCheckpointDirect = true
        }
        if UITestDriver.phaseIntroDirect {
            showPhaseIntroDirect = true
        }
        if UITestDriver.gap, let progress = progressList.first {
            progress.lastSessionDate = Date.now.addingTimeInterval(-3 * 86_400)
            try? modelContext.save()
        }
        if let count = UITestDriver.sessionsCount {
            DevDataFactory.seedSessionCount(
                count,
                progress: progressList.first,
                context: modelContext
            )
        }
        #if DEBUG
        if let name = UITestDriver.profileName {
            let profile = AdaptiveRebootEngineDriver.ensureProfile(context: modelContext)
            let injected = AdaptiveDebug.profile(name: name)
            profile.goalsRaw = injected.goalsRaw
            profile.primaryGoal = injected.primaryGoal
            profile.primaryDistractor = injected.primaryDistractor
            profile.checkMomentsRaw = injected.checkMomentsRaw
            profile.capacityBucket = injected.capacityBucket
            profile.returnDifficulty = injected.returnDifficulty
            profile.readsTenPages = injected.readsTenPages
            profile.switchingFrequency = injected.switchingFrequency
            profile.existingFlowActivitiesRaw = injected.existingFlowActivitiesRaw
            profile.flowDifferenceRaw = injected.flowDifferenceRaw
            profile.phoneLocation = injected.phoneLocation
            profile.notificationsLevel = injected.notificationsLevel
            profile.openTabsBucket = injected.openTabsBucket
            profile.usesScreenTimeLimits = injected.usesScreenTimeLimits
            profile.bestWindow = injected.bestWindow
            profile.typicalSleep = injected.typicalSleep
            profile.currentEnergy = injected.currentEnergy
            profile.caffeine = injected.caffeine
            try? modelContext.save()
            if injected.currentEnergy == "Low" {
                AdaptiveRebootEngineDriver.recordEnergyCheckIn(
                    energy: "Low",
                    sleep: injected.typicalSleep,
                    caffeine: injected.caffeine,
                    window: injected.bestWindow,
                    context: modelContext
                )
            }
            AdaptiveRebootEngineDriver.generatePrescription(forDay: 10, context: modelContext)
        }
        if UITestDriver.engineTests {
            for line in EngineTests.run() {
                print("ENGINE-TEST: \(line)")
            }
        }
        #endif
        if let raw = UITestDriver.milestone {
            switch raw {
            case "day30": testMilestone = .day30
            case "day60": testMilestone = .day60
            case "day90": testMilestone = .day90
            default: break
            }
        }
    }

    private var initialTab: MainTabsView.AppTab {
        switch UITestDriver.selectedTab {
        case "train": return .train
        case "trace": return .trace
        case "profile": return .profile
        default: return .today
        }
    }
    #else
    private var initialTab: MainTabsView.AppTab {
        .today
    }
    #endif
}

struct MainTabsView: View {
    @Query private var progressList: [RebootProgress]
    @State private var selection: AppTab
    @State private var showProgramSheet = false
    @State private var showFlowLabSheet = false
    @State private var showExperimentsSheet = false
    @State private var showSettingsSheet = false
    @State private var showCheckpoint = false
    @State private var showPhaseIntro = false
    @State private var tourMilestone: Milestone?
    @State private var tourSession: SessionMode?
    @State private var exploreMode: SessionMode?
    @Environment(\.modelContext) private var modelContext

    enum AppTab: Hashable {
        case today
        case train
        case trace
        case profile
    }

    init(initialSelection: AppTab = .today) {
        self._selection = State(initialValue: initialSelection)
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            Group {
                switch selection {
                case .today:
                    TodayView()
                case .train:
                    TrainView()
                case .trace:
                    TraceView()
                case .profile:
                    ProfileView()
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 8)),
                removal: .opacity
            ))
            .id(selection)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RBDockTabBar(
                selection: $selection,
                tabs: [
                    (.today, "TODAY"),
                    (.train, "TRAIN"),
                    (.trace, "TRACE"),
                    (.profile, "PROFILE")
                ]
            )
        }
        .fullScreenCover(isPresented: $showProgramSheet) {
            NavigationStack {
                ProgramView()
            }
        }
        .fullScreenCover(isPresented: $showFlowLabSheet) {
            FlowLabView()
        }
        .fullScreenCover(isPresented: $showExperimentsSheet) {
            ExperimentsView()
        }
        .fullScreenCover(isPresented: $showSettingsSheet) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(item: $exploreMode) { mode in
            ExploreLibraryView(mode: mode)
        }
        .fullScreenCover(item: $tourMilestone) { milestone in
            MilestoneView(milestone: milestone) {
                tourMilestone = nil
            }
        }
        .fullScreenCover(isPresented: $showCheckpoint) {
            CheckpointView(week: 1) {
                showCheckpoint = false
            }
        }
        .fullScreenCover(isPresented: $showPhaseIntro) {
            PhaseIntroView(phase: 2) {
                showPhaseIntro = false
            }
        }
        .fullScreenCover(item: $tourSession) { mode in
            SessionFlowView(
                request: SessionRequest(
                    mode: mode,
                    day: 10,
                    duration: mode == .nothing ? 5 : 10,
                    title: ProtocolCurriculum.day(10).title,
                    contentID: ProtocolCurriculum.day(10).contentID,
                    skipSetup: true,
                    fastTimer: true
                )
            )
        }
        .onAppear {
            #if DEBUG
            if UITestDriver.autoTour {
                runTour()
            }
            #endif
        }
    }

    #if DEBUG
    private func runTour() {
        Task {
            // Inject adaptive profile A + populated data at tour start.
            let profile = AdaptiveRebootEngineDriver.ensureProfile(context: modelContext)
            let injected = AdaptiveDebug.profile(name: "A")
            profile.goalsRaw = injected.goalsRaw
            profile.primaryGoal = injected.primaryGoal
            profile.primaryDistractor = injected.primaryDistractor
            profile.checkMomentsRaw = injected.checkMomentsRaw
            profile.capacityBucket = injected.capacityBucket
            profile.returnDifficulty = injected.returnDifficulty
            profile.readsTenPages = injected.readsTenPages
            profile.switchingFrequency = injected.switchingFrequency
            profile.existingFlowActivitiesRaw = injected.existingFlowActivitiesRaw
            profile.flowDifferenceRaw = injected.flowDifferenceRaw
            profile.phoneLocation = injected.phoneLocation
            profile.notificationsLevel = injected.notificationsLevel
            profile.openTabsBucket = injected.openTabsBucket
            profile.usesScreenTimeLimits = injected.usesScreenTimeLimits
            profile.bestWindow = injected.bestWindow
            profile.typicalSleep = injected.typicalSleep
            profile.currentEnergy = injected.currentEnergy
            profile.caffeine = injected.caffeine
            try? modelContext.save()
            DevDataFactory.populate(
                progress: progressList.first,
                sessions: (try? modelContext.fetch(FetchDescriptor<TrainingSession>())) ?? [],
                context: modelContext
            )
            if let progress = progressList.first {
                DevDataFactory.setDay(10, progress: progress, context: modelContext)
            }
            AdaptiveRebootEngineDriver.generatePrescription(forDay: 10, context: modelContext)

            // 1. Today with adaptive prescription + energy check-in.
            try? await Task.sleep(nanoseconds: 7_000_000_000)
            // 2. STAY session → debrief.
            tourSession = .stay
            try? await Task.sleep(nanoseconds: 14_000_000_000)
            tourSession = nil
            // 3. RECALL session → reconstruction → mock analysis → debrief.
            tourSession = .recall
            try? await Task.sleep(nanoseconds: 18_000_000_000)
            tourSession = nil
            // 4. EXPLAIN session.
            tourSession = .explain
            try? await Task.sleep(nanoseconds: 16_000_000_000)
            tourSession = nil
            // 5. NOTHING session.
            tourSession = .nothing
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            tourSession = nil
            // 6. OBSERVE session.
            tourSession = .observe
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            tourSession = nil
            // Train.
            withAnimation(RBMotion.tabTransition) { selection = .train }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            // Explore libraries.
            exploreMode = .recall
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            exploreMode = nil
            exploreMode = .explain
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            exploreMode = nil
            exploreMode = .observe
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            exploreMode = nil
            // Program.
            showProgramSheet = true
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            showProgramSheet = false
            // Trace.
            withAnimation(RBMotion.tabTransition) { selection = .trace }
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            // Profile.
            withAnimation(RBMotion.tabTransition) { selection = .profile }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            // Settings.
            showSettingsSheet = true
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            showSettingsSheet = false
            // Flow Lab.
            showFlowLabSheet = true
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            showFlowLabSheet = false
            // Experiments.
            showExperimentsSheet = true
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            showExperimentsSheet = false
            // Milestones + checkpoint + phase intro.
            tourMilestone = .day30
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            tourMilestone = .day90
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            tourMilestone = nil
            showCheckpoint = true
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            showCheckpoint = false
            showPhaseIntro = true
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            showPhaseIntro = false
            // Back to Today.
            withAnimation(RBMotion.tabTransition) { selection = .today }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }
    }
    #endif
}
