import Foundation
import Observation

/// Wall-clock based Pomodoro-style timer: survives backgrounding because progress is derived
/// from timestamps rather than counted ticks.
@Observable
final class FocusTimer: Identifiable {
    enum Phase { case work, rest }

    let id = UUID()
    let title: String
    let pillar: Int
    let habitID: UUID?

    var workMinutes: Int
    var breakMinutes: Int
    var rounds: Int

    private(set) var round = 1
    private(set) var phase: Phase = .work
    private(set) var started = false
    private(set) var running = false
    private(set) var finished = false
    private(set) var completed = false
    private(set) var startedAt = Date()

    private var phaseEnd = Date()
    private var pausedRemaining: TimeInterval = 0
    private var bankedWork: TimeInterval = 0
    private var segmentStart = Date()
    var now = Date()

    /// Filled in by the view after rewards are committed.
    var rewardedMinutes = 0
    var checkedOff = false

    init(title: String, pillar: Int, habitID: UUID?, work: Int, rest: Int, rounds: Int) {
        self.title = title
        self.pillar = pillar
        self.habitID = habitID
        self.workMinutes = work
        self.breakMinutes = rest
        self.rounds = rounds
        self.pausedRemaining = TimeInterval(work * 60)
    }

    var phaseLength: TimeInterval { TimeInterval((phase == .work ? workMinutes : breakMinutes) * 60) }

    var remaining: TimeInterval {
        running ? max(0, phaseEnd.timeIntervalSince(now)) : pausedRemaining
    }

    var progress: Double { phaseLength > 0 ? 1 - remaining / phaseLength : 0 }

    var workSeconds: TimeInterval {
        bankedWork + ((running && phase == .work) ? max(0, now.timeIntervalSince(segmentStart)) : 0)
    }

    var earnedMinutes: Int { Int(workSeconds / 60) }

    func configure(work: Int, rest: Int, rounds: Int) {
        guard !started else { return }
        workMinutes = work
        breakMinutes = rest
        self.rounds = rounds
        pausedRemaining = TimeInterval(work * 60)
    }

    func start(at date: Date = Date()) {
        guard !started else { return }
        started = true
        startedAt = date
        pausedRemaining = TimeInterval(workMinutes * 60)
        resume(at: date)
    }

    func resume(at date: Date = Date()) {
        guard started, !running, !finished else { return }
        running = true
        now = date
        segmentStart = date
        phaseEnd = date.addingTimeInterval(pausedRemaining)
    }

    func pause(at date: Date = Date()) {
        guard running else { return }
        tick(date)
        guard running else { return }
        if phase == .work { bankedWork += max(0, date.timeIntervalSince(segmentStart)) }
        pausedRemaining = max(0, phaseEnd.timeIntervalSince(date))
        running = false
    }

    /// Ends the session early, keeping all fully focused minutes.
    func end(at date: Date = Date()) {
        if running { pause(at: date) }
        finished = true
        completed = false
        running = false
    }

    /// Advances phases based on the wall clock. Returns true if a phase boundary was crossed.
    @discardableResult
    func tick(_ date: Date = Date()) -> Bool {
        now = date
        var crossed = false
        while running && date >= phaseEnd {
            crossed = true
            if phase == .work {
                bankedWork += max(0, phaseEnd.timeIntervalSince(segmentStart))
                if round < rounds {
                    phase = .rest
                    segmentStart = phaseEnd
                    phaseEnd = phaseEnd.addingTimeInterval(TimeInterval(breakMinutes * 60))
                } else {
                    running = false
                    finished = true
                    completed = true
                    pausedRemaining = 0
                }
            } else {
                round += 1
                phase = .work
                segmentStart = phaseEnd
                phaseEnd = phaseEnd.addingTimeInterval(TimeInterval(workMinutes * 60))
            }
        }
        return crossed
    }

    /// Upcoming phase boundaries, used to schedule local notifications.
    func upcomingBoundaries() -> [(Date, String, String)] {
        guard running else { return [] }
        var list: [(Date, String, String)] = []
        var end = phaseEnd
        var ph = phase
        var r = round
        while true {
            if ph == .work {
                if r < rounds {
                    list.append((end, "Break time ☕", "Round \(r) of \(title) done. Stand up, stretch, drink water."))
                    ph = .rest
                    end = end.addingTimeInterval(TimeInterval(breakMinutes * 60))
                } else {
                    list.append((end, "Session complete 🎉", "\(title) is done. Come collect your shells!"))
                    break
                }
            } else {
                r += 1
                list.append((end, "Lock in ⛏️", "Round \(r) of \(title) starts now."))
                ph = .work
                end = end.addingTimeInterval(TimeInterval(workMinutes * 60))
            }
        }
        return list
    }
}
