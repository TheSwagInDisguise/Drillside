import SwiftUI
import SwiftData
import Observation

enum AppTab: Hashable { case island, drill, log, shop }

@Observable
final class Router {
    var tab: AppTab = .island
    var timer: FocusTimer?
    var showSettings = false
    /// Prop to start placing when jumping into the island editor from the shop.
    var pendingPlacement: PropType?
    var openEditor = false
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [Profile]
    @State private var router = Router()
    @State private var toasts = ToastCenter()

    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabs(profile: profile)
                    .preferredColorScheme(scheme(for: profile.theme))
            } else {
                ProgressView().task { Seeder.seedIfNeeded(context) }
            }
        }
        .environment(router)
        .environment(toasts)
        .task { LiveActivityController.shared.endAll() }
    }

    private func scheme(for theme: String) -> ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

struct MainTabs: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var sessions: [FocusSession]
    @Query private var logs: [LogEntry]
    @Query private var placed: [PlacedProp]
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            IslandView(profile: profile)
                .tabItem { Label("Island", systemImage: "leaf") }
                .tag(AppTab.island)
            DrillView(profile: profile)
                .tabItem { Label("DRILL", systemImage: "checkmark.square") }
                .tag(AppTab.drill)
            LogView(profile: profile)
                .tabItem { Label("Log", systemImage: "book.closed") }
                .tag(AppTab.log)
            ShopView(profile: profile)
                .tabItem { Label("Shop", systemImage: "bag") }
                .tag(AppTab.shop)
        }
        .tint(Theme.accent)
        .task {
            // Resume (or pay out) a focus session that was running when the app was terminated.
            if router.timer == nil, let restored = FocusSessionStore.load() {
                router.timer = restored
            }
            AutoBackup.runIfDue(context: context)
            checkAchievements()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { AutoBackup.runIfDue(context: context) }
        }
        .onChange(of: profile.xp) { _, _ in checkAchievements() }
        .onChange(of: profile.level) { _, _ in checkAchievements() }
        .onChange(of: placed.count) { _, _ in checkAchievements() }
        .onChange(of: profile.companions.count) { _, _ in checkAchievements() }
        .onOpenURL(perform: handleDeepLink)
        .overlay { ToastOverlay().allowsHitTesting(!toasts.items.isEmpty) }
        .fullScreenCover(item: $router.timer) { timer in
            FocusTimerView(timer: timer, profile: profile)
                .environment(toasts)
                .environment(router)
        }
        .sheet(isPresented: $router.showSettings) {
            SettingsView(profile: profile)
                .environment(toasts)
        }
    }

    private func checkAchievements() {
        let stats = AchievementEngine.stats(profile: profile, habits: habits, sessions: sessions, logs: logs, placedCount: placed.count)
        let fresh = AchievementEngine.evaluate(profile: profile, stats: stats)
        guard !fresh.isEmpty else { return }
        try? context.save()
        if fresh.count == 1, let a = fresh.first {
            toasts.show("🏆 \(a.title)! \(a.rewardLabel)", duration: 4)
        } else {
            toasts.show("🏆 \(fresh.count) achievements earned! Check Shop › Awards", duration: 4.5)
        }
    }

    /// drillside://focus, drillside://checkin, drillside://drill, drillside://island, drillside://review
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "drillside" else { return }
        switch url.host ?? "" {
        case "focus":
            guard router.timer == nil else { return }
            let today = Day.today
            let active = habits.filter { !$0.archived }
            if let h = active.first(where: { $0.kind == .focus && $0.rules.meta(today).due && !$0.isDone(today) }) {
                router.timer = FocusTimer(title: h.name, pillar: h.pillar, habitID: h.id, work: h.focusMinutes,
                                          rest: profile.breakMinutes, rounds: 1)
            } else {
                router.timer = FocusTimer(title: "Quick focus", pillar: 4, habitID: nil, work: profile.workMinutes,
                                          rest: profile.breakMinutes, rounds: profile.rounds)
            }
        case "checkin", "log", "review": router.tab = .log
        case "drill": router.tab = .drill
        case "shop": router.tab = .shop
        default: router.tab = .island
        }
    }
}
