import SwiftUI
import SwiftData
import Combine

struct FocusTimerView: View {
    @Bindable var timer: FocusTimer
    let profile: Profile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ToastCenter.self) private var toasts
    @Environment(Router.self) private var router
    @Query private var habits: [Habit]
    @State private var committed = false
    @State private var bump = 0

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var color: Color { Pillars.color(timer.pillar) }
    private var pillarName: String { profile.pillarName(timer.pillar) }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if timer.finished { result } else { running }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onReceive(ticker) { date in
            let before = timer.earnedMinutes
            let crossed = timer.tick(date)
            if timer.earnedMinutes > before { bump += 1 }
            if crossed && !timer.finished {
                toasts.show(timer.phase == .rest ? "☕ Break: stand up, stretch, drink water" : "⛏️ Round \(timer.round): lock in")
            }
        }
        .onChange(of: timer.finished) { _, done in
            if done { commit() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { timer.tick(Date()) }
        }
        .sensoryFeedback(.increase, trigger: bump)
        .sensoryFeedback(.success, trigger: timer.finished)
    }

    private var background: some View {
        ZStack {
            Theme.timerBackground
            RadialGradient(colors: [color.opacity(0.55), .clear], center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: 420)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                close()
            } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(timer.started && !timer.finished ? "End session and collect" : "Close")
            Spacer()
            HStack(spacing: 6) {
                PillarBadge(pillar: timer.pillar, name: pillarName, size: 24)
                Text(pillarName).font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .padding(.leading, 5).padding(.trailing, 10).padding(.vertical, 5)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.top, 6)
    }

    private var running: some View {
        VStack(spacing: 0) {
            Text(timer.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.top, 18)
            Text("\(timer.phase == .work ? "Focus" : "Break") · round \(timer.round) of \(timer.rounds)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .textCase(.uppercase).kerning(1)
                .opacity(0.75)
                .padding(.top, 2)

            ZStack {
                Circle().stroke(.white.opacity(0.1), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: max(0.001, timer.progress))
                    .stroke(timer.phase == .work ? color : Color(hex: 0x7FD3D8), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: timer.progress)
                VStack(spacing: 4) {
                    MoleBadge(timer: timer).frame(width: 96, height: 64)
                    Text(Self.clock(timer.remaining))
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                    Text("+\(timer.earnedMinutes) XP · +\(timer.earnedMinutes) 🐚")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                        .scaleEffect(bump % 2 == 0 ? 1 : 1.12)
                        .animation(.spring(duration: 0.3), value: bump)
                }
            }
            .frame(width: 250, height: 250)
            .padding(.vertical, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Self.clock(timer.remaining)) remaining, \(timer.earnedMinutes) minutes earned")

            if timer.started {
                HStack(spacing: 6) {
                    ForEach(0..<timer.rounds, id: \.self) { i in
                        Capsule()
                            .fill(i < timer.round - 1 ? color : (i == timer.round - 1 ? .white : .white.opacity(0.18)))
                            .frame(width: 28, height: 6)
                    }
                }
            } else {
                config
            }

            Spacer(minLength: 12)

            VStack(spacing: 8) {
                Button {
                    toggle()
                } label: {
                    Text(timer.running ? "Pause" : (timer.started ? "Resume" : "Start focus"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0x141826))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
                if timer.started {
                    Button {
                        endEarly()
                    } label: {
                        Text("End & collect")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                Text("+1 XP and +1 🐚 for every focused minute")
                    .font(.system(size: 12)).opacity(0.6)
                    .padding(.top, 4)
            }
        }
    }

    private var config: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach([25, 50, 90], id: \.self) { work in
                    let rest = work == 25 ? 5 : (work == 50 ? 10 : 15)
                    let on = timer.workMinutes == work && timer.breakMinutes == rest
                    Button("\(work)/\(rest)") {
                        timer.configure(work: work, rest: rest, rounds: timer.rounds)
                    }
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(on ? Color(hex: 0x141826) : .white)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(on ? Color.white : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            StepperRow(title: "Work", value: timer.workMinutes, unit: "min", range: 5...120, step: 5) {
                timer.configure(work: $0, rest: timer.breakMinutes, rounds: timer.rounds)
            }
            StepperRow(title: "Break", value: timer.breakMinutes, unit: "min", range: 1...30) {
                timer.configure(work: timer.workMinutes, rest: $0, rounds: timer.rounds)
            }
            StepperRow(title: "Rounds", value: timer.rounds, unit: "", range: 1...8) {
                timer.configure(work: timer.workMinutes, rest: timer.breakMinutes, rounds: $0)
            }
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .tint(.white)
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private var result: some View {
        VStack(spacing: 0) {
            Spacer()
            MoleBadge(timer: timer, celebrating: true).frame(width: 150, height: 110)
            Text(timer.completed ? "Session complete!" : "Nice effort")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .padding(.top, 10)
            Text("\(timer.rewardedMinutes) focused minute\(timer.rewardedMinutes == 1 ? "" : "s") · \(timer.title)")
                .opacity(0.75)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            HStack(spacing: 10) {
                rewardTile("+\(timer.rewardedMinutes)", "XP")
                rewardTile("+\(timer.rewardedMinutes)", "🐚 shells")
            }
            .padding(.vertical, 20)
            if timer.checkedOff {
                Text("✓ “\(timer.title)” checked off (+\(Economy.habitXP) XP)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.good.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
            VStack(spacing: 8) {
                Button {
                    dismiss()
                } label: {
                    Text("Back to island")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0x141826))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
                Button {
                    router.tab = .log
                    dismiss()
                } label: {
                    Text("Add a note to today’s log")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func rewardTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 28, weight: .heavy, design: .rounded))
            Text(label).font(.system(size: 12, weight: .bold)).opacity(0.75)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Actions

    private func toggle() {
        if !timer.started {
            timer.start()
            Task {
                if await Notifier.requestAuthorization() {
                    Notifier.scheduleFocusBoundaries(timer.upcomingBoundaries())
                }
            }
        } else if timer.running {
            timer.pause()
            Notifier.cancelFocus()
        } else {
            timer.resume()
            Notifier.scheduleFocusBoundaries(timer.upcomingBoundaries())
        }
    }

    private func endEarly() {
        timer.end()
    }

    private func close() {
        if timer.started && !timer.finished {
            timer.end()
        } else if !timer.finished || committed {
            Notifier.cancelFocus()
            dismiss()
        }
    }

    private func commit() {
        guard !committed else { return }
        committed = true
        Notifier.cancelFocus()
        let minutes = timer.earnedMinutes
        let result = Game.commitFocus(minutes: minutes, completed: timer.completed, habitID: timer.habitID, title: timer.title,
                                      startedAt: timer.startedAt, profile: profile, habits: habits, context: context)
        timer.rewardedMinutes = minutes
        timer.checkedOff = result.checkedOff
        if result.levels > 0 {
            toasts.levelUp(result.levels, level: profile.level) { router.tab = .shop }
        }
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

/// Animated Bitsy for the timer: hammering while focusing, snoozing during breaks.
private struct MoleBadge: View {
    let timer: FocusTimer
    var celebrating = false

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = CGFloat(tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000))
                let k = size.width / 96
                var g = ctx
                g.scaleBy(x: k, y: k)
                if celebrating {
                    MoleArt.draw(g, 48, 60, 1.5, MolePose(t: t, bob: abs(sin(t * 5)) * 6, cheering: true))
                    return
                }
                let working = timer.running && timer.phase == .work
                let resting = timer.phase == .rest
                MoleArt.draw(g, 48, 62, 1.35, MolePose(t: t, bob: working ? abs(sin(t * 9)) * 2 : 0,
                                                        sleeping: resting, hammering: working))
                if resting {
                    let off = (t * 8).truncatingRemainder(dividingBy: 10)
                    g.draw(Text("z").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.8)), at: P(64, 22 - off))
                    g.draw(Text("z").font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.8)), at: P(71, 14 - off / 2))
                }
                if working {
                    for i in 0..<3 {
                        let k2 = (t * 1.5 + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1)
                        let r = 1.6 * (1 - k2) + 0.2
                        g.ell(66 + k2 * 14, 42 - k2 * 10, r, r, Color(hex: 0xFFDC78, opacity: Double(1 - k2)))
                    }
                }
            }
        }
    }
}
