import ActivityKit
import SwiftUI
import WidgetKit

@main
struct DrillsideWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusLiveActivity()
    }
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            LockScreenFocusView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color(hex: 0x121521))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let a = context.attributes
            let s = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        PillarDot(attributes: a, size: 26)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(s.phaseLabel).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(.secondary)
                            Text("Round \(s.round)/\(s.rounds)").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CountdownText(state: s)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(s.isBreak ? Color(hex: 0x7FD3D8) : a.pillarColor)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(a.title).font(.system(size: 15, weight: .bold, design: .rounded)).lineLimit(1)
                            Spacer()
                            Text("+\(s.earnedMinutes) XP · +\(s.earnedMinutes) 🐚").font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        PhaseProgress(state: s, tint: s.isBreak ? Color(hex: 0x7FD3D8) : a.pillarColor)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: s.isFinished ? "checkmark.circle.fill" : (s.isBreak ? "cup.and.saucer.fill" : "hammer.fill"))
                    .foregroundStyle(s.isBreak ? Color(hex: 0x7FD3D8) : a.pillarColor)
            } compactTrailing: {
                CountdownText(state: s)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(s.isBreak ? Color(hex: 0x7FD3D8) : a.pillarColor)
                    .frame(maxWidth: 46)
            } minimal: {
                MinimalRing(state: s, tint: s.isBreak ? Color(hex: 0x7FD3D8) : a.pillarColor)
            }
            .keylineTint(a.pillarColor)
        }
    }
}

/// Self-updating countdown while running; static time while paused.
struct CountdownText: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        if state.isFinished {
            Text("Done")
        } else if state.isRunning && state.phaseEnd > Date() {
            Text(timerInterval: state.phaseStart...state.phaseEnd, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        } else {
            Text(FocusActivityAttributes.ContentState.clock(state.remaining))
                .monospacedDigit()
        }
    }
}

struct PhaseProgress: View {
    let state: FocusActivityAttributes.ContentState
    let tint: Color

    var body: some View {
        Group {
            if state.isRunning && !state.isFinished && state.phaseEnd > Date() {
                ProgressView(timerInterval: state.phaseStart...state.phaseEnd, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(value: state.isFinished ? 1 : state.progress)
            }
        }
        .progressViewStyle(.linear)
        .tint(tint)
    }
}

struct MinimalRing: View {
    let state: FocusActivityAttributes.ContentState
    let tint: Color

    var body: some View {
        Group {
            if state.isRunning && !state.isFinished && state.phaseEnd > Date() {
                ProgressView(timerInterval: state.phaseStart...state.phaseEnd, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: state.isBreak ? "cup.and.saucer.fill" : "hammer.fill").font(.system(size: 9))
                }
            } else {
                ProgressView(value: state.isFinished ? 1 : 1 - state.progress) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: state.isFinished ? "checkmark" : "pause.fill").font(.system(size: 9))
                }
            }
        }
        .progressViewStyle(.circular)
        .tint(tint)
    }
}

struct PillarDot: View {
    let attributes: FocusActivityAttributes
    var size: CGFloat = 26

    var body: some View {
        Text(attributes.pillarLetter)
            .font(.system(size: size * 0.5, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(attributes.pillarColor, in: RoundedRectangle(cornerRadius: size / 3, style: .continuous))
    }
}

struct LockScreenFocusView: View {
    let attributes: FocusActivityAttributes
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        let tint = state.isBreak ? Color(hex: 0x7FD3D8) : attributes.pillarColor
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PillarDot(attributes: attributes, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                    Text(state.isFinished ? "Session complete · Drillside"
                         : "\(state.phaseLabel) · round \(state.round) of \(state.rounds)\(state.isRunning ? "" : " · paused")")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                CountdownText(state: state)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(tint)
                    .frame(maxWidth: 120, alignment: .trailing)
            }
            PhaseProgress(state: state, tint: tint)
            HStack {
                Text("⛏️ Bitsy is \(state.isFinished ? "celebrating" : (state.isBreak ? "napping" : (state.isRunning ? "drilling in" : "waiting")))")
                Spacer()
                Text("+\(state.earnedMinutes) XP · +\(state.earnedMinutes) 🐚")
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.75))
        }
        .foregroundStyle(.white)
        .padding(16)
    }
}
