import ActivityKit
import SwiftUI

// Compiled into BOTH the app and the DrillsideWidgets extension.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Live Activity describing a running focus session (Dynamic Island + Lock Screen).
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var isRunning: Bool
        var isFinished: Bool
        /// Virtual start of the current phase (phaseEnd − phase length) so progress views are accurate.
        var phaseStart: Date
        var phaseEnd: Date
        var remaining: TimeInterval
        var round: Int
        var rounds: Int
        var earnedMinutes: Int
    }

    var title: String
    var pillarName: String
    var pillarLetter: String
    var pillarColorHex: UInt32

    var pillarColor: Color { Color(hex: pillarColorHex) }
}

extension FocusActivityAttributes.ContentState {
    var progress: Double {
        let total = phaseEnd.timeIntervalSince(phaseStart)
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - remaining / total))
    }

    var phaseLabel: String {
        if isFinished { return "Done" }
        return isBreak ? "Break" : "Focus"
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
