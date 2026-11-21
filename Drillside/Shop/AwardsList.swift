import SwiftUI
import SwiftData

struct AwardsList: View {
    let profile: Profile
    @Query private var habits: [Habit]
    @Query private var sessions: [FocusSession]
    @Query private var logs: [LogEntry]
    @Query private var placed: [PlacedProp]

    var body: some View {
        let stats = AchievementEngine.stats(profile: profile, habits: habits, sessions: sessions, logs: logs, placedCount: placed.count)
        let owned = Set(profile.achievements)
        let sorted = Achievement.allCases.sorted { a, b in
            let ua = owned.contains(a.rawValue), ub = owned.contains(b.rawValue)
            if ua != ub { return !ua }
            let pa = a.progress(stats), pb = b.progress(stats)
            return Double(pa.0) / Double(max(1, pa.1)) > Double(pb.0) / Double(max(1, pb.1))
        }
        VStack(spacing: 10) {
            HStack {
                Text("\(owned.count) of \(Achievement.allCases.count) earned").font(.system(size: 14, weight: .heavy, design: .rounded))
                Spacer()
                Text("Trophy props go to your inventory").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            ForEach(sorted) { a in
                let p = a.progress(stats)
                let done = owned.contains(a.rawValue)
                HStack(spacing: 12) {
                    Text(a.icon).font(.system(size: 26))
                        .frame(width: 44, height: 44)
                        .background(done ? Theme.accent.opacity(0.18) : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                        .saturation(done ? 1 : 0.2)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(a.title).font(.system(size: 15, weight: .heavy, design: .rounded))
                            Spacer()
                            Text(done ? "✓ Earned" : a.rewardLabel)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(done ? Theme.good : .secondary)
                        }
                        Text(a.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                        if !done {
                            ProgressView(value: Double(min(p.0, p.1)), total: Double(max(1, p.1)))
                                .tint(Theme.accent)
                            Text("\(min(p.0, p.1)) / \(p.1)").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}
