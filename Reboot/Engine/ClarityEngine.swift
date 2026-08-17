import Foundation
import SwiftData

/// REBOOT's internal training indicator.
///
/// Clarity is NOT a medical, diagnostic, neurological, clinical or IQ
/// measure. It is an internal training signal derived ONLY from real
/// evaluation dimensions produced by actual restitutions.
///
/// ALGORITHM (documented):
/// 1. Collect every EvaluationResult attached to a TrainingSession.
/// 2. If fewer than 3 evaluable sessions exist, Clarity cannot be computed.
/// 3. From each evaluation, take the dimension named "CLARTÉ" when present;
///    otherwise fall back to the dimension closest to the attention family
///    (FOCUS, CLARTÉ, STRUCTURE, STABILITY).
/// 4. Average those dimension scores across sessions → raw signal 0...10.
/// 5. Clarity = raw * 10 → 0...100 internal scale.
/// 6. Confidence grows with sample size: provisional under 7 sessions,
///    established from 7+. Missing dimensions are never substituted with
///    a default value; if no dimension is usable, no number is produced.
///
/// Statuses:
/// - 0 sessions                → NO SIGNAL
/// - 1 session                 → CALIBRATION 1/3
/// - 2 sessions                → CALIBRATION 2/3
/// - 3–6 sessions              → PROVISIONAL (real value if evaluable)
/// - 7+ sessions               → ESTABLISHED (real value if evaluable)
/// - sessions exist, no evaluations → ANALYSE EN ATTENTE
@MainActor
enum ClarityEngine {
    struct Result: Equatable {
        enum Status: String {
            case noSignal = "NO SIGNAL"
            case calibration1 = "CALIBRATION 1/3"
            case calibration2 = "CALIBRATION 2/3"
            case provisional = "PROVISIONAL"
            case established = "ESTABLISHED"
            case pendingAnalysis = "ANALYSE EN ATTENTE"
        }

        let status: Status
        let value: Double?
        let confidence: Double
        let sampleSize: Int
    }

    private static let attentionDimensionNames = ["CLARTÉ", "FOCUS", "STRUCTURE", "STABILITY", "STABILITÉ"]

    static func compute(sessions: [TrainingSession]) -> Result {
        let count = sessions.count
        guard count > 0 else {
            return Result(status: .noSignal, value: nil, confidence: 0, sampleSize: 0)
        }
        guard count >= 3 else {
            let status: Result.Status = count == 1 ? .calibration1 : .calibration2
            return Result(status: status, value: nil, confidence: 0, sampleSize: count)
        }

        let evaluations = sessions.compactMap { $0.evaluation }
        guard !evaluations.isEmpty else {
            return Result(status: .pendingAnalysis, value: nil, confidence: 0, sampleSize: count)
        }

        var usableScores: [Double] = []
        for evaluation in evaluations {
            let preferred = evaluation.dimensions.first { $0.name.uppercased() == "CLARTÉ" }
                ?? evaluation.dimensions.first { dimension in
                    attentionDimensionNames.contains { dimension.name.uppercased().contains($0) }
                }
            if let preferred {
                usableScores.append(preferred.score)
            }
        }

        guard !usableScores.isEmpty else {
            return Result(status: .pendingAnalysis, value: nil, confidence: 0, sampleSize: count)
        }

        let raw = usableScores.reduce(0, +) / Double(usableScores.count)
        let value = (raw * 10 * 10).rounded() / 10
        let status: Result.Status = count >= 7 ? .established : .provisional
        let confidence = min(1.0, Double(count) / 12.0)
        return Result(status: status, value: value, confidence: confidence, sampleSize: count)
    }
}
