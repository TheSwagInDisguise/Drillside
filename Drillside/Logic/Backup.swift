import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Versioned, human-readable JSON snapshot of everything stored on device.
struct BackupFile: Codable {
    static let currentVersion = 1

    struct ProfileDTO: Codable {
        var level: Int, xp: Int, shells: Int, islandSize: Int
        var inventory: [String], companions: [String]
        var pillarNames: [String], pillarHints: [String]
        var workMinutes: Int, breakMinutes: Int, rounds: Int
        var reminderOn: Bool, reminderHour: Int, reminderMinute: Int
        var theme: String, isNight: Bool
    }
    struct HabitDTO: Codable {
        var id: UUID, name: String, pillar: Int, kind: String, focusMinutes: Int
        var schedule: String, n: Int, startKey: String, sortOrder: Int, doneKeys: [String], createdAt: Date
    }
    struct SessionDTO: Codable {
        var id: UUID, startedAt: Date, dayKey: String, minutes: Int, habitID: UUID?, title: String, completed: Bool
    }
    struct LogDTO: Codable {
        var dayKey: String, well: String, wrong: String, fix: String, tag: String, updatedAt: Date
    }
    struct PropDTO: Codable {
        var type: String, row: Int, col: Int
    }

    var app: String = "Drillside"
    var version: Int = BackupFile.currentVersion
    var exportedAt: Date = Date()
    var profile: ProfileDTO
    var habits: [HabitDTO]
    var sessions: [SessionDTO]
    var logs: [LogDTO]
    var props: [PropDTO]

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

@MainActor
enum BackupService {
    static func makeBackup(context: ModelContext) throws -> Data {
        guard let p = try context.fetch(FetchDescriptor<Profile>()).first else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        let habits = try context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))
        let sessions = try context.fetch(FetchDescriptor<FocusSession>(sortBy: [SortDescriptor(\.startedAt)]))
        let logs = try context.fetch(FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.dayKey)]))
        let props = try context.fetch(FetchDescriptor<PlacedProp>())

        let file = BackupFile(
            profile: .init(level: p.level, xp: p.xp, shells: p.shells, islandSize: p.islandSize,
                           inventory: p.inventory, companions: p.companions,
                           pillarNames: p.pillarNames, pillarHints: p.pillarHints,
                           workMinutes: p.workMinutes, breakMinutes: p.breakMinutes, rounds: p.rounds,
                           reminderOn: p.reminderOn, reminderHour: p.reminderHour, reminderMinute: p.reminderMinute,
                           theme: p.theme, isNight: p.isNight),
            habits: habits.map { .init(id: $0.id, name: $0.name, pillar: $0.pillar, kind: $0.kindRaw, focusMinutes: $0.focusMinutes,
                                       schedule: $0.scheduleRaw, n: $0.scheduleN, startKey: $0.startKey, sortOrder: $0.sortOrder,
                                       doneKeys: $0.doneKeys.sorted(), createdAt: $0.createdAt) },
            sessions: sessions.map { .init(id: $0.id, startedAt: $0.startedAt, dayKey: $0.dayKey, minutes: $0.minutes,
                                           habitID: $0.habitID, title: $0.title, completed: $0.completed) },
            logs: logs.map { .init(dayKey: $0.dayKey, well: $0.well, wrong: $0.wrong, fix: $0.fix, tag: $0.tag, updatedAt: $0.updatedAt) },
            props: props.map { .init(type: $0.typeRaw, row: $0.row, col: $0.col) })
        return try BackupFile.encoder.encode(file)
    }

    /// Replaces all local data with the backup's contents.
    static func restore(_ data: Data, context: ModelContext) throws {
        let file = try BackupFile.decoder.decode(BackupFile.self, from: data)
        guard file.version <= BackupFile.currentVersion else { throw CocoaError(.fileReadCorruptFile) }

        Seeder.eraseEverything(context)

        let p = Profile()
        let d = file.profile
        p.level = max(1, d.level); p.xp = max(0, d.xp); p.shells = max(0, d.shells)
        p.islandSize = min(Economy.maxIsland, max(Economy.minIsland, d.islandSize))
        p.inventory = d.inventory.filter { PropType(rawValue: $0) != nil }
        p.companions = d.companions.filter { CompanionType(rawValue: $0) != nil }
        p.pillarNames = d.pillarNames.count == 5 ? d.pillarNames : Pillars.defaultNames
        p.pillarHints = d.pillarHints.count == 5 ? d.pillarHints : Pillars.defaultHints
        p.workMinutes = d.workMinutes; p.breakMinutes = d.breakMinutes; p.rounds = d.rounds
        p.reminderOn = d.reminderOn; p.reminderHour = d.reminderHour; p.reminderMinute = d.reminderMinute
        p.theme = d.theme; p.isNight = d.isNight
        context.insert(p)

        for h in file.habits {
            let habit = Habit(name: h.name, pillar: min(4, max(0, h.pillar)), kind: HabitKind(rawValue: h.kind) ?? .habit,
                              focusMinutes: h.focusMinutes, schedule: ScheduleKind(rawValue: h.schedule) ?? .daily,
                              n: max(1, h.n), startKey: h.startKey, sortOrder: h.sortOrder)
            habit.id = h.id
            habit.doneKeys = h.doneKeys
            habit.createdAt = h.createdAt
            context.insert(habit)
        }
        for s in file.sessions {
            let fs = FocusSession(startedAt: s.startedAt, dayKey: s.dayKey, minutes: s.minutes, habitID: s.habitID, title: s.title, completed: s.completed)
            fs.id = s.id
            context.insert(fs)
        }
        for l in file.logs {
            let e = LogEntry(dayKey: l.dayKey, well: l.well, wrong: l.wrong, fix: l.fix)
            e.tag = l.tag
            e.updatedAt = l.updatedAt
            context.insert(e)
        }
        for pr in file.props {
            guard let t = PropType(rawValue: pr.type) else { continue }
            context.insert(PlacedProp(type: t, row: pr.row, col: pr.col))
        }
        try context.save()
    }
}

/// Wrapper so SwiftUI's `fileExporter` can write the backup.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
