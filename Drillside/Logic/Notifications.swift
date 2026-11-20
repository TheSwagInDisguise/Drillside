import Foundation
import UserNotifications

/// Local-only notifications (no push, no entitlements).
enum Notifier {
    static let dailyID = "daily-checkin"
    static let focusPrefix = "focus-phase-"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    static func scheduleDailyReminder(hour: Int, minute: Int) async {
        guard await requestAuthorization() else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])
        let content = UNMutableNotificationContent()
        content.title = "Quick check-in 🏝️"
        content.body = "What went well? What went wrong? One line each. Bitsy is waiting."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyID])
    }

    /// Schedules one notification per upcoming phase boundary of a running focus session.
    static func scheduleFocusBoundaries(_ boundaries: [(Date, String, String)]) {
        let center = UNUserNotificationCenter.current()
        cancelFocus()
        for (i, b) in boundaries.enumerated() {
            let interval = b.0.timeIntervalSinceNow
            guard interval > 1 else { continue }
            let content = UNMutableNotificationContent()
            content.title = b.1
            content.body = b.2
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            center.add(UNNotificationRequest(identifier: focusPrefix + String(i), content: content, trigger: trigger))
        }
    }

    static func cancelFocus() {
        let ids = (0..<20).map { focusPrefix + String($0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
