#if DEBUG
import Foundation

/// DEBUG-only driver: launch-arguments navigate and complete flows for QA.
/// Never compiled into Release builds.
enum UITestDriver {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var isActive: Bool {
        arguments.contains {
            $0.hasPrefix("-uitest")
                || $0 == "-OnboardingPage"
                || $0 == "-ResetOnboarding"
                || $0 == "-OnboardingAutoAdvance"
        }
    }

    static var skipOnboarding: Bool {
        arguments.contains("-uitest-skip-onboarding")
    }

    static var autoFinishOnboarding: Bool {
        arguments.contains("-uitest-onboarding-finish")
    }

    static var initialOnboardingPage: Int {
        intValue("-uitest-onboarding-page") ?? intValue("-OnboardingPage") ?? 0
    }

    static var resetOnboarding: Bool {
        arguments.contains("-uitest-reset-onboarding") || arguments.contains("-ResetOnboarding")
    }

    static var selectedTab: String {
        stringValue("-uitest-tab") ?? "today"
    }

    static var sessionMode: String? {
        stringValue("-uitest-session")
    }

    static var sessionDay: Int {
        intValue("-uitest-day") ?? 1
    }

    static var sessionDuration: Int {
        intValue("-uitest-duration") ?? 10
    }

    static var setDay: Int? {
        intValue("-uitest-set-day")
    }

    static var milestone: String? {
        stringValue("-uitest-milestone")
    }

    static var mockEval: Bool {
        arguments.contains("-uitest-mock-eval")
    }

    static var fastTimer: Bool {
        arguments.contains("-uitest-fast-timer")
    }

    static var sessionSetup: Bool {
        arguments.contains("-uitest-session-setup")
    }

    static var populated: Bool {
        arguments.contains("-uitest-populated")
    }

    static var settings: Bool {
        arguments.contains("-uitest-settings")
    }

    static var program: Bool {
        arguments.contains("-uitest-program")
    }

    static var autoAdvanceOnboarding: Bool {
        arguments.contains("-OnboardingAutoAdvance")
    }

    static var engineTests: Bool {
        arguments.contains("-EngineTests")
    }

    static var autoTour: Bool {
        arguments.contains("-AutoTour")
    }

    static var diagnosisAutoAdvance: Bool {
        arguments.contains("-DiagnosisAutoAdvance")
    }

    static var profileName: String? {
        guard let index = arguments.firstIndex(of: "-Profile"), arguments.count > index + 1 else { return nil }
        return arguments[index + 1]
    }

    static var gap: Bool {
        arguments.contains("-uitest-gap")
    }

    static var sessionsCount: Int? {
        intValue("-uitest-sessions")
    }

    static var exploreMode: String? {
        stringValue("-uitest-explore")
    }

    static var flowLab: Bool {
        arguments.contains("-uitest-flowlab")
    }

    static var flowSession: Bool {
        arguments.contains("-uitest-flow-session")
    }

    static var flowAutoFinish: Bool {
        arguments.contains("-uitest-flow-autofinish")
    }

    static var observeAutoReflect: Bool {
        arguments.contains("-uitest-observe-reflect")
    }

    static var programAll: Bool {
        arguments.contains("-uitest-program-all")
    }

    static var traceDetail: Bool {
        arguments.contains("-uitest-trace-detail")
    }

    static var flowBuilderAuto: Bool {
        arguments.contains("-uitest-flow-builder")
    }

    static var experimentsDirect: Bool {
        arguments.contains("-uitest-experiments")
    }

    static var experimentsAutoTemplates: Bool {
        arguments.contains("-uitest-experiments-templates")
    }

    static var checkpointDirect: Bool {
        arguments.contains("-uitest-checkpoint")
    }

    static var phaseIntroDirect: Bool {
        arguments.contains("-uitest-phaseintro")
    }

    static var holdReconstruction: Bool {
        arguments.contains("-uitest-hold-reconstruction")
    }

    static var forceOffline: Bool {
        arguments.contains("-uitest-offline")
    }

    private static func intValue(_ key: String) -> Int? {
        guard let index = arguments.firstIndex(of: key), arguments.count > index + 1 else {
            return nil
        }
        return Int(arguments[index + 1])
    }

    private static func stringValue(_ key: String) -> String? {
        guard let index = arguments.firstIndex(of: key), arguments.count > index + 1 else {
            return nil
        }
        return arguments[index + 1]
    }
}
#endif
