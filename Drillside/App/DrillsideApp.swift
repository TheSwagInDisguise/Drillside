import SwiftUI
import SwiftData

@main
struct DrillsideApp: App {
    let container: ModelContainer

    init() {
        // Local-only store: no CloudKit, no App Group, so no entitlements are required.
        do {
            container = try Store.makeContainer()
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
