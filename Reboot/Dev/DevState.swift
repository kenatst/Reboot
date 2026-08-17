#if DEBUG
import Foundation

/// DEBUG-only state for the developer navigation.
@MainActor
enum DevState {
    private static let defaults = UserDefaults.standard
    private static let mockKey = "dev.mockEvaluation"
    private static let offlineKey = "dev.forceEvaluationOffline"
    private static let populatedKey = "dev.populatedOnce"

    static var mockEvaluation: Bool {
        get { defaults.bool(forKey: mockKey) }
        set { defaults.set(newValue, forKey: mockKey) }
    }

    static var forceEvaluationOffline: Bool {
        get { defaults.bool(forKey: offlineKey) }
        set { defaults.set(newValue, forKey: offlineKey) }
    }

    static var populatedOnce: Bool {
        get { defaults.bool(forKey: populatedKey) }
        set { defaults.set(newValue, forKey: populatedKey) }
    }
}
#endif
