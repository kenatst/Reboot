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
            PreferencesStore.shared.onboardingShownAtLeastOnce = true
            #if DEBUG
            if UITestDriver.isActive {
                configureForUITest()
            }
            #endif
            if !PreferencesStore.shared.onboardingCompleted {
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
                if commit {
                    RBHaptics.play(.lock)
                }
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
    private func configureForUITest() {
        DevState.mockEvaluation = UITestDriver.mockEval
        DevState.forceEvaluationOffline = UITestDriver.forceOffline
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
    @State private var selection: AppTab

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
        TabView(selection: $selection) {
            TodayView()
                .tabItem {
                    Label("AUJOURD'HUI", systemImage: "circle")
                }
                .tag(AppTab.today)
            TrainView()
                .tabItem {
                    Label("ENTRAÎNER", systemImage: "square")
                }
                .tag(AppTab.train)
            TraceView()
                .tabItem {
                    Label("TRACE", systemImage: "triangle")
                }
                .tag(AppTab.trace)
            ProfileView()
                .tabItem {
                    Label("PROFIL", systemImage: "hexagon")
                }
                .tag(AppTab.profile)
        }
    }
}
