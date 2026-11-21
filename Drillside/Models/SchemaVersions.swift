import Foundation
import SwiftData

// MARK: - Versioned schemas
//
// How to change the data model from now on:
// 1. Copy the current top-level models into a new frozen `SchemaVn` enum below (exactly as they are).
// 2. Edit the top-level models and point `DrillsideSchemaLatest` at them with a bumped version.
// 3. Add a `MigrationStage` (lightweight when only adding defaulted fields, custom otherwise).
// Never edit a frozen schema: its shape must match what is already on people's devices.

/// Frozen copy of the store shape shipped in v1.2.0 (the first versioned release).
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 2, 0) }
    static var models: [any PersistentModel.Type] { [Profile.self, Habit.self, FocusSession.self, LogEntry.self, PlacedProp.self] }

    @Model final class Profile {
        var level: Int = 1
        var xp: Int = 0
        var shells: Int = 0
        var islandSize: Int = 6
        var inventory: [String] = []
        var companions: [String] = []
        var pillarNames: [String] = []
        var pillarHints: [String] = []
        var workMinutes: Int = 25
        var breakMinutes: Int = 5
        var rounds: Int = 2
        var reminderOn: Bool = false
        var reminderHour: Int = 21
        var reminderMinute: Int = 0
        var theme: String = "system"
        var isNight: Bool = false
        var skyMode: String = "auto"
        var liveActivityOn: Bool = true
        var createdAt: Date = Date()
        init() {}
    }

    @Model final class Habit {
        var id: UUID = UUID()
        var name: String = ""
        var pillar: Int = 0
        var kindRaw: String = "habit"
        var focusMinutes: Int = 25
        var scheduleRaw: String = "daily"
        var scheduleN: Int = 1
        var startKey: String = ""
        var sortOrder: Int = 0
        var doneKeys: [String] = []
        var createdAt: Date = Date()
        init(name: String) { self.name = name }
    }

    @Model final class FocusSession {
        var id: UUID = UUID()
        var startedAt: Date = Date()
        var dayKey: String = ""
        var minutes: Int = 0
        var habitID: UUID?
        var title: String = ""
        var completed: Bool = false
        init() {}
    }

    @Model final class LogEntry {
        @Attribute(.unique) var dayKey: String = ""
        var well: String = ""
        var wrong: String = ""
        var fix: String = ""
        var tag: String = ""
        var updatedAt: Date = Date()
        init(dayKey: String) { self.dayKey = dayKey }
    }

    @Model final class PlacedProp {
        var id: UUID = UUID()
        var typeRaw: String = "tree"
        var row: Int = 0
        var col: Int = 0
        init() {}
    }
}

/// Frozen copy of the v1.3.0 store: habits gained archive fields.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 3, 0) }
    static var models: [any PersistentModel.Type] { [Profile.self, Habit.self, FocusSession.self, LogEntry.self, PlacedProp.self] }

    @Model final class Profile {
        var level: Int = 1
        var xp: Int = 0
        var shells: Int = 0
        var islandSize: Int = 6
        var inventory: [String] = []
        var companions: [String] = []
        var pillarNames: [String] = []
        var pillarHints: [String] = []
        var workMinutes: Int = 25
        var breakMinutes: Int = 5
        var rounds: Int = 2
        var reminderOn: Bool = false
        var reminderHour: Int = 21
        var reminderMinute: Int = 0
        var theme: String = "system"
        var isNight: Bool = false
        var skyMode: String = "auto"
        var liveActivityOn: Bool = true
        var createdAt: Date = Date()
        init() {}
    }

    @Model final class Habit {
        var id: UUID = UUID()
        var name: String = ""
        var pillar: Int = 0
        var kindRaw: String = "habit"
        var focusMinutes: Int = 25
        var scheduleRaw: String = "daily"
        var scheduleN: Int = 1
        var startKey: String = ""
        var sortOrder: Int = 0
        var doneKeys: [String] = []
        var createdAt: Date = Date()
        var archived: Bool = false
        var archivedAt: Date?
        var pauses: [String] = []
        init(name: String) { self.name = name }
    }

    @Model final class FocusSession {
        var id: UUID = UUID()
        var startedAt: Date = Date()
        var dayKey: String = ""
        var minutes: Int = 0
        var habitID: UUID?
        var title: String = ""
        var completed: Bool = false
        init() {}
    }

    @Model final class LogEntry {
        @Attribute(.unique) var dayKey: String = ""
        var well: String = ""
        var wrong: String = ""
        var fix: String = ""
        var tag: String = ""
        var updatedAt: Date = Date()
        init(dayKey: String) { self.dayKey = dayKey }
    }

    @Model final class PlacedProp {
        var id: UUID = UUID()
        var typeRaw: String = "tree"
        var row: Int = 0
        var col: Int = 0
        init() {}
    }
}

/// v1.4.0: habit quantities & notes, achievements, weekly review, focus sounds, seasons, island themes.
enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 4, 0) }
    static var models: [any PersistentModel.Type] { AppSchema.models }
}

typealias DrillsideSchemaLatest = SchemaV3

enum DrillsideMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self, SchemaV3.self] }
    static var stages: [MigrationStage] { [v1ToV2, v2ToV3] }

    static let v1ToV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    static let v2ToV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)
}

enum Store {
    static let name = "Drillside"

    /// Opens the on-device store with the versioned migration plan. If the store predates versioning
    /// (v1.0/v1.1) it falls back to SwiftData's automatic lightweight migration, which handles the
    /// added-with-default fields those versions differ by.
    static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: DrillsideSchemaLatest.self)
        let config: ModelConfiguration
        if let url {
            config = ModelConfiguration(schema: schema, url: url, allowsSave: true, cloudKitDatabase: .none)
        } else {
            config = ModelConfiguration(name, schema: schema, isStoredInMemoryOnly: inMemory,
                                        allowsSave: true, groupContainer: .none, cloudKitDatabase: .none)
        }
        do {
            return try ModelContainer(for: schema, migrationPlan: DrillsideMigrationPlan.self, configurations: [config])
        } catch {
            NSLog("Drillside: versioned open failed (\(error)); retrying with automatic migration")
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
