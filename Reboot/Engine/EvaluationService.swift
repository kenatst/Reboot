import Foundation

enum EvaluationService {
    @MainActor
    static var provider: EvaluationProvider {
        #if DEBUG
        if DevState.forceEvaluationOffline {
            return OfflineSimulationProvider()
        }
        if DevState.mockEvaluation || ProcessInfo.processInfo.environment["REBOOT_MOCK_EVALUATION"] == "1" {
            return MockEvaluationProvider()
        }
        #endif
        return RemoteEvaluationProvider()
    }
}

#if DEBUG
struct OfflineSimulationProvider: EvaluationProvider {
    func evaluate(_ request: EvaluationRequest) async throws -> EvaluationResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        throw EvaluationError.offline
    }
}
#endif
