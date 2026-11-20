import SwiftUI
import SwiftData

@main
struct DrillsideApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema(AppSchema.models)
        // Local-only store: no CloudKit, no App Group, so no entitlements are required.
        let config = ModelConfiguration("Drillside", schema: schema, isStoredInMemoryOnly: false,
                                        allowsSave: true, groupContainer: .none, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not open the local database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
