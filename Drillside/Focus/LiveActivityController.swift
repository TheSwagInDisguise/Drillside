import ActivityKit
import Foundation

/// Starts / updates / ends the focus-session Live Activity shown in the Dynamic Island and on the Lock Screen.
/// Purely local (no push token), so no entitlements are needed.
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()
    private var activity: Activity<FocusActivityAttributes>?

    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(for timer: FocusTimer, pillarName: String) {
        guard isAvailable else { return }
        endAll()
        let attributes = FocusActivityAttributes(
            title: timer.title,
            pillarName: pillarName,
            pillarLetter: Pillars.letter(pillarName),
            pillarColorHex: Pillars.hex(timer.pillar))
        let state = Self.state(for: timer)
        do {
            activity = try Activity.request(attributes: attributes,
                                            content: ActivityContent(state: state, staleDate: state.phaseEnd.addingTimeInterval(60)),
                                            pushType: nil)
        } catch {
            activity = nil
        }
    }

    func update(_ timer: FocusTimer) {
        guard let activity else { return }
        let state = Self.state(for: timer)
        let content = ActivityContent(state: state, staleDate: state.isRunning ? state.phaseEnd.addingTimeInterval(60) : nil)
        Task { await activity.update(content) }
    }

    func finish(_ timer: FocusTimer) {
        guard let activity else { return }
        var state = Self.state(for: timer)
        state.isFinished = true
        state.isRunning = false
        state.remaining = 0
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(10 * 60))) }
        self.activity = nil
    }

    /// Ends every activity (e.g. leftovers from a session the app was killed during).
    func endAll() {
        for a in Activity<FocusActivityAttributes>.activities {
            Task { await a.end(nil, dismissalPolicy: .immediate) }
        }
        activity = nil
    }

    static func state(for timer: FocusTimer) -> FocusActivityAttributes.ContentState {
        let now = Date()
        let end = timer.running ? timer.phaseEndDate : now.addingTimeInterval(timer.remaining)
        return .init(isBreak: timer.phase == .rest,
                     isRunning: timer.running,
                     isFinished: timer.finished,
                     phaseStart: end.addingTimeInterval(-timer.phaseLength),
                     phaseEnd: end,
                     remaining: timer.remaining,
                     round: timer.round,
                     rounds: timer.rounds,
                     earnedMinutes: timer.earnedMinutes)
    }
}
