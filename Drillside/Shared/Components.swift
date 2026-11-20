import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct Chip: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct PillarBadge: View {
    var pillar: Int
    var name: String
    var size: CGFloat = 30

    var body: some View {
        Text(Pillars.letter(name))
            .font(.system(size: size * 0.5, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Pillars.color(pillar), in: RoundedRectangle(cornerRadius: size / 3, style: .continuous))
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle().stroke(Color(.tertiarySystemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: progress)
        }
    }
}

struct StepperRow: View {
    var title: String
    var value: Int
    var unit: String
    var range: ClosedRange<Int>
    var step: Int = 1
    var onChange: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                Button { onChange(max(range.lowerBound, value - step)) } label: {
                    Image(systemName: "minus").frame(width: 30, height: 28)
                }
                Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 58)
                Button { onChange(min(range.upperBound, value + step)) } label: {
                    Image(systemName: "plus").frame(width: 30, height: 28)
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 8))
            .controlSize(.small)
        }
    }
}

/// Simple wrapping layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for v in subviews {
            let sz = v.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > width {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let sz = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}

/// Static rendering of a prop / companion / Bitsy standing on a single tile (shop, inventory, icons).
struct ThumbView: View {
    enum Kind { case prop(PropType), companion(CompanionType), mole, land(Int) }
    var kind: Kind
    var dimmed = false

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 80
            var g = ctx
            g.scaleBy(x: k, y: k)
            g.translateBy(x: (size.width / k - 80) / 2, y: (size.height / k - 80) / 2)
            switch kind {
            case .prop(let t):
                TileArt.tile(g, 40, 52, halfWidth: 28, depth: 7)
                PropArt.draw(t, g, 40, 54, 0.85, 0.6, night: 0)
            case .companion(let t):
                TileArt.tile(g, 40, 52, halfWidth: 28, depth: 7)
                CompanionArt.draw(t, g, 40, 54, 1.6, 0.3, face: 1)
            case .mole:
                TileArt.tile(g, 40, 52, halfWidth: 28, depth: 7)
                MoleArt.draw(g, 40, 58, 1.25, MolePose(t: 1))
            case .land(let n):
                drawLand(g, n)
            }
        }
        .saturation(dimmed ? 0 : 1)
        .opacity(dimmed ? 0.5 : 1)
    }

    private func drawLand(_ g: GraphicsContext, _ n: Int) {
        let hw: CGFloat = min(9, 64 / CGFloat(n))
        let nn = CGFloat(n)
        func pt(_ r: CGFloat, _ c: CGFloat) -> CGPoint {
            P(40 + (c - r) * hw, 40 + (c + r) * hw / 2 - nn * hw / 4)
        }
        let l = pt(nn, 0), b = pt(nn, nn), r = pt(0, nn)
        g.poly([l, b, P(b.x, b.y + 6), P(l.x, l.y + 6)], Ink.dirtLeft)
        g.poly([b, r, P(r.x, r.y + 6), P(b.x, b.y + 6)], Ink.dirtRight)
        for row in 0..<n {
            for col in 0..<n {
                let rr = CGFloat(row), cc = CGFloat(col)
                let tile = [pt(rr, cc), pt(rr, cc + 1), pt(rr + 1, cc + 1), pt(rr + 1, cc)]
                g.poly(tile, (row + col) % 2 == 1 ? Ink.grassB : Ink.grassA)
                g.polyStroke(tile, .white.opacity(0.35), 0.6)
            }
        }
    }
}
