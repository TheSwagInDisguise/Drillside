import SwiftUI
import Observation

@Observable
final class ToastCenter {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        var text: String
        var actionTitle: String?
        static func == (a: Item, b: Item) -> Bool { a.id == b.id }
    }

    var items: [Item] = []
    @ObservationIgnored private var actions: [UUID: () -> Void] = [:]

    func show(_ text: String, actionTitle: String? = nil, duration: Double = 2.6, action: (() -> Void)? = nil) {
        let item = Item(text: text, actionTitle: actionTitle)
        if let action { actions[item.id] = action }
        withAnimation(.spring(duration: 0.3)) {
            items.append(item)
            if items.count > 3 { items.removeFirst(items.count - 3) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismiss(item.id)
        }
    }

    func levelUp(_ levels: Int, level: Int, openShop: @escaping () -> Void) {
        guard levels > 0 else { return }
        show("🎉 Level \(level)! Check the shop for new items", actionTitle: "Shop", duration: 3.8, action: openShop)
    }

    func dismiss(_ id: UUID) {
        withAnimation(.easeOut(duration: 0.25)) { items.removeAll { $0.id == id } }
        actions[id] = nil
    }

    func perform(_ id: UUID) {
        actions[id]?()
        dismiss(id)
    }
}

struct ToastOverlay: View {
    @Environment(ToastCenter.self) private var toasts

    var body: some View {
        VStack(spacing: 6) {
            ForEach(toasts.items) { item in
                HStack(spacing: 10) {
                    Text(item.text)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let title = item.actionTitle {
                        Button(title) { toasts.perform(item.id) }
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(Color(hex: 0x1C202A, opacity: 0.95), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { toasts.dismiss(item.id) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
