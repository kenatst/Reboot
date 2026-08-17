import Foundation

/// What the user is about to train.
struct SessionRequest: Identifiable {
    let id = UUID()
    let mode: SessionMode
    let day: Int
    let duration: Int
    let title: String
    let contentID: Int?
    var skipSetup = false
    var fastTimer = false
}

/// Builds a request for the current protocol day, or a free discipline.
enum SessionRequestFactory {
    static func today(day: Int) -> SessionRequest {
        let plan = ProtocolCurriculum.day(day)
        return SessionRequest(
            mode: plan.mode,
            day: day,
            duration: plan.recommendedDuration,
            title: plan.title,
            contentID: plan.contentID
        )
    }

    static func discipline(_ mode: SessionMode, day: Int) -> SessionRequest {
        let plan = ProtocolCurriculum.day(day)
        let contentID: Int?
        switch mode {
        case .recall: contentID = ((day - 1) % 50) + 1
        case .explain: contentID = ((day - 1) % 35) + 1
        case .observe: contentID = ((day - 1) % 35) + 1
        default: contentID = nil
        }
        let suggested = ProtocolEngine.suggestedDurations(for: mode, day: day).last ?? plan.recommendedDuration
        return SessionRequest(
            mode: mode,
            day: day,
            duration: suggested,
            title: plan.title,
            contentID: contentID
        )
    }
}
