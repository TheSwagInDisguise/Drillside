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
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { AutoBackup.runIfDue(context: context) }
        }
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
}
