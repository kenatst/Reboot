import Foundation
import SwiftData

/// Lightweight preference store backed by UserDefaults. Kept separate from
/// SwiftData so settings are available before the model container is ready
/// and survive destructive data resets.
@MainActor
final class PreferencesStore {
    static let shared = PreferencesStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let haptics = "prefs.haptics"
        static let sessionSound = "prefs.sessionSound"
        static let reminderEnabled = "prefs.reminderEnabled"
        static let reminderHour = "prefs.reminderHour"
        static let appearance = "prefs.appearance"
        static let onboardingCompleted = "prefs.onboardingCompleted"
        static let onboardingShownAtLeastOnce = "prefs.onboardingShown"
    }

    init() {}

    var hapticsEnabled: Bool {
        get { defaults.object(forKey: Key.haptics) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.haptics) }
    }

    var sessionSoundEnabled: Bool {
        get { defaults.object(forKey: Key.sessionSound) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.sessionSound) }
    }

    var reminderEnabled: Bool {
        get { defaults.object(forKey: Key.reminderEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.reminderEnabled) }
    }

    var reminderHour: Int {
        get { defaults.object(forKey: Key.reminderHour) as? Int ?? 8 }
        set { defaults.set(max(0, min(23, newValue)), forKey: Key.reminderHour) }
    }

    var appearance: String {
        get { defaults.string(forKey: Key.appearance) ?? "system" }
        set { defaults.set(newValue, forKey: Key.appearance) }
    }

    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Key.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Key.onboardingCompleted) }
    }

    var onboardingShownAtLeastOnce: Bool {
        get { defaults.bool(forKey: Key.onboardingShownAtLeastOnce) }
        set { defaults.set(newValue, forKey: Key.onboardingShownAtLeastOnce) }
    }
}
