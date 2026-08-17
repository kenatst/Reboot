import SwiftUI
import SwiftData

@main
struct RebootApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            TrainingSession.self,
            EvaluationResult.self,
            Restitution.self,
            RebootProgress.self,
            ProtocolDayCompletion.self,
            WeeklyCheckpoint.self,
            SelfEvaluation.self,
            ClaritySnapshot.self
        ])
        if let resolved = Self.makeContainer(schema: schema) {
            container = resolved
        } else {
            // Last-resort fallback: never crash at launch. Data will not
            // persist across launches in this pathological case, but the
            // app remains usable and the disk store is retried next launch.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: [fallback]))
                ?? { fatalError("Could not create model container") }()
        }
    }

    private static func makeContainer(schema: Schema) -> ModelContainer? {
        // Ensure the Application Support directory exists before CoreData
        // attempts to create the store (avoids a first-launch race).
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        if let supportURL {
            try? FileManager.default.createDirectory(
                at: supportURL,
                withIntermediateDirectories: true
            )
        }
        let storeURL = supportURL?.appendingPathComponent("Reboot.store")
            ?? URL.documentsDirectory.appendingPathComponent("Reboot.store")
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // One retry with a fresh default configuration.
            let retry = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try? ModelContainer(for: schema, configurations: [retry])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
