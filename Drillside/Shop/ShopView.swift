import SwiftUI
import SwiftData

struct ShopView: View {
    @Bindable var profile: Profile
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Query private var placed: [PlacedProp]

    enum Category: String, CaseIterable, Identifiable { case props = "Props", companions = "Companions", land = "Land"; var id: String { rawValue } }
    @State private var category: Category = .props
    @State private var buyTick = 0
    @State private var failTick = 0

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    editCTA
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch category {
                    case .props:
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(PropType.allCases) { propCard($0) }
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
                                       action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            thumb
                .frame(width: 104, height: 104)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(LinearGradient(colors: [Color(hex: 0xD9F3F2), Color(hex: 0xBCE6E6)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 14))
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
        let owned = inInv + placed.filter { $0.type == t }.count
        let locked = profile.level < t.unlockLevel
        let subtitle = locked ? "Unlocks at level \(t.unlockLevel)"
            : (owned > 0 ? "Owned ×\(owned)" + (inInv > 0 ? " · \(inInv) unplaced" : "") : t.blurb)
        return itemCard(thumb: ThumbView(kind: .prop(t), dimmed: locked), title: t.name, subtitle: subtitle,
                        button: locked ? "Level \(t.unlockLevel)" : "🐚 \(t.price)", enabled: !locked, locked: locked) {
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
                        enabled: !own && !locked, locked: locked && !own) {
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
        return VStack(spacing: 6) {
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
                    Text("🐚 \(Economy.expandPrice(from: n))")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func openEditor(_ prop: PropType?) {
        router.pendingPlacement = prop
        router.openEditor = true
        router.tab = .island
    }
}
