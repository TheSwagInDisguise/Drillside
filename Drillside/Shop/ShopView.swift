import SwiftUI
import SwiftData

struct ShopView: View {
    @Bindable var profile: Profile
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Query private var placed: [PlacedProp]

    enum Tab: Hashable, Identifiable {
        case props(PropCategory), companions, land
        var id: String {
            switch self {
            case .props(let c): return c.rawValue
            case .companions: return "companions"
            case .land: return "land"
            }
        }
        var title: String {
            switch self {
            case .props(let c): return c.title
            case .companions: return "Companions"
            case .land: return "Land"
            }
        }
        var icon: String {
            switch self {
            case .props(let c): return c.icon
            case .companions: return "pawprint.fill"
            case .land: return "map.fill"
            }
        }
        static var all: [Tab] { PropCategory.allCases.map { Tab.props($0) } + [.companions, .land] }
    }
    @State private var tab: Tab = .props(.nature)
    @State private var buyTick = 0
    @State private var failTick = 0

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    editCTA
                    tabBar
                    unlockTeaser

                    switch tab {
                    case .props(let cat):
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(PropType.items(in: cat)) { propCard($0) }
                        }
                    case .companions:
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(CompanionType.allCases) { companionCard($0) }
                        }
                    case .land:
                        landCard
                    }

                    Text("Earn shells by focusing (1 per minute), checking habits and logging.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Island Shop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("🐚 \(profile.shells)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.default, value: profile.shells)
                        .accessibilityLabel("\(profile.shells) shells")
                }
            }
            .sensoryFeedback(.success, trigger: buyTick)
            .sensoryFeedback(.error, trigger: failTick)
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tab.all) { t in
                    let on = t == tab
                    let fresh = newCount(t)
                    Button {
                        withAnimation(.snappy) { tab = t }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: t.icon).font(.system(size: 12))
                            Text(t.title)
                            if fresh > 0 {
                                Text("\(fresh)")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(Theme.bad, in: Capsule())
                            }
                        }
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
                        .padding(.horizontal, 12).frame(height: 34)
                        .background(on ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// Items unlocked at exactly the current level that the player doesn't own yet.
    private func newCount(_ t: Tab) -> Int {
        switch t {
        case .props(let c):
            return PropType.items(in: c).filter { $0.unlockLevel == profile.level && profile.level > 1 && owned($0) == 0 }.count
        case .companions:
            return CompanionType.allCases.filter { $0.unlockLevel == profile.level && !profile.companions.contains($0.rawValue) }.count
        case .land:
            return 0
        }
    }

    private func owned(_ t: PropType) -> Int { profile.inventoryCount(t) + placed.filter { $0.type == t }.count }

    @ViewBuilder
    private var unlockTeaser: some View {
        let next = (PropType.allCases.map(\.unlockLevel) + CompanionType.allCases.map(\.unlockLevel)).filter { $0 > profile.level }.min()
        if let lvl = next {
            let count = PropType.allCases.filter { $0.unlockLevel == lvl }.count + CompanionType.allCases.filter { $0.unlockLevel == lvl }.count
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill").foregroundStyle(Theme.accent)
                Text("Reach **level \(lvl)** to unlock \(count) more item\(count == 1 ? "" : "s")")
                Spacer()
                Text("\(profile.xp)/\(Economy.xpNeeded(forLevel: profile.level)) XP").foregroundStyle(.secondary)
            }
            .font(.system(size: 13, design: .rounded))
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var editCTA: some View {
        HStack(spacing: 12) {
            ThumbView(kind: .mole).frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("Edit Mode").font(.system(size: 16, weight: .heavy, design: .rounded))
                Text("Move and place decorations anywhere on your island grid").font(.system(size: 12.5)).opacity(0.9)
            }
            Spacer(minLength: 0)
            Button("Edit") { openEditor(nil) }
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x2D7F92))
                .padding(.horizontal, 14).frame(height: 36)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(LinearGradient(colors: [Color(hex: 0x5DC6CF), Color(hex: 0x3E9FB3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func itemCard<Thumb: View>(thumb: Thumb, title: String, subtitle: String, button: String, enabled: Bool, locked: Bool,
                                       isNew: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            thumb
                .frame(width: 104, height: 104)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(LinearGradient(colors: [Color(hex: 0xD9F3F2), Color(hex: 0xBCE6E6)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if isNew {
                        Text("NEW")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.bad, in: Capsule())
                            .padding(6)
                    }
                }
            Text(title).font(.system(size: 14, weight: .heavy, design: .rounded)).lineLimit(1)
            Text(subtitle).font(.system(size: 11.5)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineLimit(2).frame(minHeight: 30, alignment: .top)
            Button(action: action) {
                HStack(spacing: 4) {
                    if locked { Image(systemName: "lock.fill").font(.system(size: 11)) }
                    Text(button)
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 36)
                .foregroundStyle(enabled ? AnyShapeStyle(Color.white) : AnyShapeStyle(.secondary))
                .background(enabled ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color(.tertiarySystemFill)), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func propCard(_ t: PropType) -> some View {
        let inInv = profile.inventoryCount(t)
        let ownedCount = owned(t)
        let locked = profile.level < t.unlockLevel
        let isNew = !locked && ownedCount == 0 && t.unlockLevel == profile.level && profile.level > 1
        let subtitle = locked ? "Unlocks at level \(t.unlockLevel)"
            : (ownedCount > 0 ? "Owned ×\(ownedCount)" + (inInv > 0 ? " · \(inInv) unplaced" : "") : t.blurb)
        return itemCard(thumb: ThumbView(kind: .prop(t), dimmed: locked), title: t.name, subtitle: subtitle,
                        button: locked ? "Level \(t.unlockLevel)" : "🐚 \(t.price)", enabled: !locked, locked: locked, isNew: isNew) {
            let out = Game.buy(t, profile: profile)
            if out.ok {
                buyTick += 1
                toasts.show(out.message ?? "", actionTitle: "Place", duration: 4) { openEditor(t) }
            } else {
                failTick += 1
                if let m = out.message { toasts.show(m) }
            }
        }
    }

    private func companionCard(_ t: CompanionType) -> some View {
        let own = profile.companions.contains(t.rawValue)
        let locked = profile.level < t.unlockLevel
        return itemCard(thumb: ThumbView(kind: .companion(t), dimmed: locked), title: t.name,
                        subtitle: locked ? "Unlocks at level \(t.unlockLevel)" : t.blurb,
                        button: own ? "✓ Lives on your island" : (locked ? "Level \(t.unlockLevel)" : "🐚 \(t.price)"),
                        enabled: !own && !locked, locked: locked && !own, isNew: !own && !locked && t.unlockLevel == profile.level) {
            let out = Game.buy(t, profile: profile)
            if out.ok {
                buyTick += 1
                toasts.show(out.message ?? "", actionTitle: "Visit", duration: 4) { router.tab = .island }
            } else {
                failTick += 1
                if let m = out.message { toasts.show(m) }
            }
        }
    }

    private var landCard: some View {
        let n = profile.islandSize
        let maxed = n >= Economy.maxIsland
        let needLevel = Economy.expandLevel(to: n + 1)
        let lockedByLevel = !maxed && profile.level < needLevel
        let price = Economy.expandPrice(from: n)
        return VStack(spacing: 12) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ThumbView(kind: .land(n)).frame(width: 110, height: 80)
                    if !maxed {
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        ThumbView(kind: .land(n + 1)).frame(width: 110, height: 80)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(LinearGradient(colors: [Color(hex: 0xD9F3F2), Color(hex: 0xBCE6E6)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 14))
                Text(maxed ? "Maximum size reached" : "Expand to \(n + 1)×\(n + 1)").font(.system(size: 15, weight: .heavy, design: .rounded))
                Text(maxed ? "\(n)×\(n) · \(n * n) tiles" : "\(n * n) → \((n + 1) * (n + 1)) tiles · \(placed.count) tiles decorated")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                if !maxed {
                    Button {
                        let out = Game.expandIsland(profile: profile)
                        if out.ok {
                            buyTick += 1
                            toasts.show(out.message ?? "", actionTitle: "See it", duration: 4) { router.tab = .island }
                        } else {
                            failTick += 1
                            if let m = out.message { toasts.show(m) }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if lockedByLevel { Image(systemName: "lock.fill").font(.system(size: 11)) }
                            Text(lockedByLevel ? "Level \(needLevel)" : "🐚 \(price)")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(lockedByLevel ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.white))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(lockedByLevel ? AnyShapeStyle(Color(.tertiarySystemFill)) : AnyShapeStyle(Theme.accent), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(lockedByLevel)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Island growth").font(.system(size: 15, weight: .heavy, design: .rounded))
                        Spacer()
                        Text("\(n)×\(n) of \(Economy.maxIsland)×\(Economy.maxIsland)").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(n - Economy.minIsland), total: Double(Economy.maxIsland - Economy.minIsland))
                        .tint(Theme.accent)
                    ForEach(maxed ? [] : Array((n + 1)...min(Economy.maxIsland, n + 4)), id: \.self) { size in
                        HStack {
                            Text("\(size)×\(size)").font(.system(size: 13, weight: .bold, design: .rounded)).frame(width: 52, alignment: .leading)
                            Text("Level \(Economy.expandLevel(to: size))")
                                .font(.system(size: 12))
                                .foregroundStyle(profile.level >= Economy.expandLevel(to: size) ? AnyShapeStyle(Theme.good) : AnyShapeStyle(.secondary))
                            Spacer()
                            Text("🐚 \(Economy.expandPrice(from: size - 1))").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                        }
                    }
                    Text("Big islands can be explored with pinch-to-zoom and drag-to-pan.")
                        .font(.system(size: 11.5)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func openEditor(_ prop: PropType?) {
        router.pendingPlacement = prop
        router.openEditor = true
        router.tab = .island
    }
}
