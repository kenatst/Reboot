#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only data manipulation shared by the developer menu and the UI test driver.
@MainActor
enum DevDataFactory {
    static func setDay(_ day: Int, progress: RebootProgress?, context: ModelContext) {
        guard let progress else { return }
        progress.completedSessions = max(0, day - 1)
        progress.currentDay = day
        progress.lastSessionDate = day > 1 ? .now : nil
        progress.coreModeUnlocked = day >= 90
        try? context.save()
    }

    static func empty(progress: RebootProgress?, sessions: [TrainingSession], context: ModelContext) {
        for session in sessions {
            context.delete(session)
        }
        progress?.completedSessions = 0
        progress?.currentDay = 1
        progress?.lastSessionDate = nil
        progress?.coreModeUnlocked = false
        try? context.save()
    }

    static func populate(progress: RebootProgress?, sessions: [TrainingSession], context: ModelContext) {
        empty(progress: progress, sessions: sessions, context: context)
        guard let progress else { return }
        let now = Date.now
        for index in 0..<7 {
            let date = now.addingTimeInterval(TimeInterval(-(6 - index) * 86_400))
            let mode: SessionMode = [.stay, .recall, .explain, .stay, .observe, .recall, .stay][index]
            let plan = ProtocolCurriculum.day(index + 1)
            let session = TrainingSession(
                date: date,
                protocolDay: index + 1,
                phase: 1,
                mode: mode,
                title: plan.title,
                intention: plan.intention,
                plannedDurationSeconds: plan.recommendedDuration * 60,
                task: mode == .stay ? "Préparer ma présentation" : "",
                sourceContent: mode == .recall ? "Texte de démonstration." : (mode == .explain ? "Leçon de démonstration." : ""),
                userResponse: mode == .recall || mode == .explain
                    ? "Je retiens l'idée centrale : rester sur une chose change la qualité de ce que je produis. L'exemple de la session m'a montré que le retour après une interruption est plus coûteux que continuer."
                    : "",
                completionOrdinal: index + 1
            )
            session.actualDurationSeconds = plan.recommendedDuration * 60
            if mode == .recall || mode == .explain {
                let evaluation = EvaluationResult(
                    sessionID: session.id,
                    overallScore: Double(5 + index),
                    dimensions: [
                        EvaluationDimension(name: "CLARTÉ", score: Double(5 + index), reason: "L'idée principale est restituée."),
                        EvaluationDimension(name: "STRUCTURE", score: Double(5 + index) - 1, reason: "Quelques étapes manquent."),
                        EvaluationDimension(name: "PRÉCISION", score: Double(5 + index) + 1, reason: "Le vocabulaire est juste.")
                    ],
                    strength: "L'idée centrale est restituée sans recopiage.",
                    mainGap: "Les étapes intermédiaires sont implicites.",
                    correction: "Nomme l'étape qui relie l'exemple au concept.",
                    nextChallenge: "Reconstruis sans aucun terme du texte source.",
                    confidence: 0.7,
                    insufficientEvidence: false,
                    followUpQuestion: nil,
                    provider: "mock"
                )
                context.insert(evaluation)
                session.evaluation = evaluation
                session.analysisAttempted = true
            }
            context.insert(session)
        }
        progress.completedSessions = 7
        progress.currentDay = 8
        progress.lastSessionDate = now
        try? context.save()
    }
}
#endif
