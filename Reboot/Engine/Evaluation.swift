import Foundation

// MARK: - Request / response

struct EvaluationRequest: Codable {
    let sessionType: String
    let sourceContent: String
    let userResponse: String
    let context: [String: String]
}

struct EvaluationResponse: Codable {
    let overallScore: Double
    let dimensions: [EvaluationDimension]
    let strength: String
    let mainGap: String
    let correction: String
    let nextChallenge: String
    let confidence: Double
    let insufficientEvidence: Bool
    let followUpQuestion: String?
}

enum EvaluationError: LocalizedError {
    case offline
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .offline: return "ANALYSIS OFFLINE."
        case .invalidResponse: return "ANALYSIS OFFLINE."
        }
    }
}

// MARK: - Provider protocol

protocol EvaluationProvider {
    func evaluate(_ request: EvaluationRequest) async throws -> EvaluationResponse
}

/// Production provider. The endpoint is injected through xcconfig into
/// Info.plist; the app never contains a secret key.
struct RemoteEvaluationProvider: EvaluationProvider {
    var endpoint: URL?
    var session: URLSession = .shared

    init(endpoint: URL? = nil) {
        if let endpoint {
            self.endpoint = endpoint
        } else if let string = Bundle.main.object(forInfoDictionaryKey: "REBOOT_EVALUATION_ENDPOINT") as? String,
                  !string.isEmpty,
                  string != "https://evaluation.example.invalid/reboot",
                  let url = URL(string: string) {
            self.endpoint = url
        } else if let env = ProcessInfo.processInfo.environment["REBOOT_EVALUATION_ENDPOINT"],
                  let url = URL(string: env) {
            self.endpoint = url
        }
    }

    func evaluate(_ request: EvaluationRequest) async throws -> EvaluationResponse {
        guard let endpoint else { throw EvaluationError.offline }
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 25
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw EvaluationError.offline
        }
        do {
            return try JSONDecoder().decode(EvaluationResponse.self, from: data)
        } catch {
            throw EvaluationError.invalidResponse
        }
    }
}

#if DEBUG
/// Development-only provider. Never compiled into Release builds. It produces
/// deterministic, clearly synthetic feedback for UI testing of the debrief.
struct MockEvaluationProvider: EvaluationProvider {
    func evaluate(_ request: EvaluationRequest) async throws -> EvaluationResponse {
        try await Task.sleep(nanoseconds: 900_000_000)
        let responseCount = request.userResponse.split(whereSeparator: \.isWhitespace).count
        let substance = min(1.0, Double(responseCount) / 80.0)
        let score = 4.0 + substance * 5.0
        return EvaluationResponse(
            overallScore: (score * 10).rounded() / 10,
            dimensions: [
                EvaluationDimension(name: "CLARTÉ", score: (score * 10).rounded() / 10, reason: "Le propos est identifiable et organisé."),
                EvaluationDimension(name: "STRUCTURE", score: min(10, (score + 0.5) * 10).rounded() / 10, reason: "Les idées principales sont reliées entre elles."),
                EvaluationDimension(name: "PRÉCISION", score: max(0, (score - 0.5) * 10).rounded() / 10, reason: "Quelques notions restent approximatives.")
            ],
            strength: "Tu restitues l'idée centrale sans la recopier.",
            mainGap: "Les étapes intermédiaires du raisonnement sont implicites.",
            correction: "Nomme l'étape qui relie l'exemple au concept avant de conclure.",
            nextChallenge: "Reconstruis le même contenu sans aucun terme du texte source.",
            confidence: 0.7,
            insufficientEvidence: responseCount < 15,
            followUpQuestion: responseCount < 15 ? "Quelle idée du texte te paraît la plus importante ?" : nil
        )
    }
}
#endif

// MARK: - Session context builder

enum EvaluationContextBuilder {
    static func request(
        mode: SessionMode,
        sourceContent: String,
        userResponse: String,
        day: Int,
        phase: Int,
        title: String
    ) -> EvaluationRequest {
        EvaluationRequest(
            sessionType: mode.rawValue,
            sourceContent: sourceContent,
            userResponse: userResponse,
            context: [
                "protocolDay": "\(day)",
                "phase": "\(phase)",
                "title": title,
                "language": "fr"
            ]
        )
    }
}
