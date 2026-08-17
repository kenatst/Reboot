import Foundation
import SwiftData

/// Pure protocol progression logic. The protocol advances when a session is
/// completed — never when a calendar day passes.
enum ProtocolEngine {
    static func currentDay(progress: RebootProgress?) -> Int {
        guard let progress else { return 1 }
        return min(90, max(1, progress.completedSessions + 1))
    }

    static func phaseNumber(forDay day: Int) -> Int {
        ProtocolCurriculum.phase(forDay: day).number
    }

    static func welcomeBackMessage(progress: RebootProgress?) -> String? {
        guard let progress, let last = progress.lastSessionDate else { return nil }
        let calendar = Calendar.current
        guard !calendar.isDateInToday(last) else { return nil }
        let day = currentDay(progress: progress)
        return "WELCOME BACK.\nDAY \(String(format: "%03d", day)) IS STILL WAITING."
    }

    // MARK: Clarity

    enum ClarityStatus: Equatable {
        case empty
        case calibrating(Int) // 1...2 of 3
        case provisional
        case normal

        var label: String {
            switch self {
            case .empty: return "—"
            case .calibrating(let n): return "CALIBRATION \(n)/3"
            case .provisional: return "PROVISIONAL"
            case .normal: return "CLARITY"
            }
        }
    }

    static func clarityStatus(sessionsCompleted: Int) -> ClarityStatus {
        switch sessionsCompleted {
        case 0: return .empty
        case 1: return .calibrating(1)
        case 2: return .calibrating(2)
        case 3...6: return .provisional
        default: return .normal
        }
    }

    // MARK: Milestones

    static func milestoneReached(completedBefore: Int, completedAfter: Int) -> Milestone? {
        if completedBefore < 90, completedAfter >= 90 { return .day90 }
        if completedBefore < 60, completedAfter >= 60 { return .day60 }
        if completedBefore < 30, completedAfter >= 30 { return .day30 }
        return nil
    }

    static func checkpointDue(completedBefore: Int, completedAfter: Int) -> Int? {
        guard completedAfter >= 7 else { return nil }
        if completedBefore / 7 == completedAfter / 7 { return nil }
        return completedAfter / 7
    }

    static func suggestedDurations(for mode: SessionMode, day: Int) -> [Int] {
        let phase = phaseNumber(forDay: day)
        switch mode {
        case .stay:
            switch phase {
            case 1: return [10, 25]
            case 2: return [15, 25, 45]
            case 3: return [25, 45, 60]
            default: return [45, 60, 90]
            }
        case .recall, .explain:
            return [15, 25, 45]
        case .nothing:
            return [5, 10, 15, 20]
        case .observe:
            return [10, 15, 20, 30]
        }
    }
}

enum Milestone: String, Identifiable {
    case day30
    case day60
    case day90

    var id: String { rawValue }

    var header: String {
        switch self {
        case .day30: return "30 DAYS."
        case .day60: return "60 DAYS."
        case .day90: return "90 DAYS."
        }
    }

    var title: String {
        switch self {
        case .day30: return "YOU'RE\nSTAYING\nLONGER."
        case .day60: return "GO\nDEEPER."
        case .day90: return "THE REBOOT\nENDS HERE.\nTHE TRAINING\nDOESN'T."
        }
    }
}
