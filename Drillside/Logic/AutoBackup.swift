import Foundation
import SwiftData

/// Weekly (and on every app update) JSON backups written to Documents/Backups, which the app exposes
/// in the Files app (Files › On My iPhone › Drillside › Backups). Keeps the newest `keep` files.
@MainActor
enum AutoBackup {
    static let enabledKey = "autoBackup.enabled"
    static let lastDateKey = "autoBackup.lastDate"
    static let lastVersionKey = "autoBackup.lastAppVersion"
    static let keep = 8
    static let interval: TimeInterval = 7 * 24 * 3600
    static let prefix = "drillside-"

    static var folder: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Backups", isDirectory: true)
    }

    static var isEnabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }

    static var lastBackup: Date? {
        let t = UserDefaults.standard.double(forKey: lastDateKey)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "?"
        let b = info?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    nonisolated static func isDue(now: Date, last: Date?, lastVersion: String?, currentVersion: String, interval: TimeInterval = 7 * 24 * 3600) -> Bool {
        guard let last else { return true }
        return now.timeIntervalSince(last) >= interval || lastVersion != currentVersion
    }

    /// File names (newest first by name, which embeds the timestamp) that should be deleted to keep `keep`.
    nonisolated static func filesToPrune(_ names: [String], keep: Int, prefix: String = "drillside-") -> [String] {
        let ours = names.filter { $0.hasPrefix(prefix) && $0.hasSuffix(".json") }.sorted(by: >)
        return Array(ours.dropFirst(max(0, keep)))
    }

    @discardableResult
    static func runIfDue(context: ModelContext, now: Date = Date()) -> URL? {
        guard isEnabled else { return nil }
        let d = UserDefaults.standard
        guard isDue(now: now, last: lastBackup, lastVersion: d.string(forKey: lastVersionKey), currentVersion: appVersion) else { return nil }
        return try? backupNow(context: context, now: now)
    }

    @discardableResult
    static func backupNow(context: ModelContext, now: Date = Date()) throws -> URL {
        let data = try BackupService.makeBackup(context: context)
        let fm = FileManager.default
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        let url = folder.appendingPathComponent("\(prefix)\(f.string(from: now)).json")
        try data.write(to: url, options: .atomic)
        let names = (try? fm.contentsOfDirectory(atPath: folder.path)) ?? []
        for name in filesToPrune(names, keep: keep) {
            try? fm.removeItem(at: folder.appendingPathComponent(name))
        }
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastDateKey)
        UserDefaults.standard.set(appVersion, forKey: lastVersionKey)
        return url
    }

    struct Entry: Identifiable, Hashable {
        let url: URL
        let date: Date
        let size: Int
        var id: URL { url }
    }

    static func list() -> [Entry] {
        let fm = FileManager.default
        let names = ((try? fm.contentsOfDirectory(atPath: folder.path)) ?? [])
            .filter { $0.hasPrefix(prefix) && $0.hasSuffix(".json") }
            .sorted(by: >)
        return names.compactMap { name in
            let url = folder.appendingPathComponent(name)
            let attrs = try? fm.attributesOfItem(atPath: url.path)
            let date = attrs?[.modificationDate] as? Date ?? Date()
            let size = (attrs?[.size] as? NSNumber)?.intValue ?? 0
            return Entry(url: url, date: date, size: size)
        }
    }
}
