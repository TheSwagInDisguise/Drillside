import SwiftUI
import WidgetKit

/// Home-screen / Lock Screen launcher. It reads no app data (that would need an App Group entitlement),
/// so it shows a time-of-day greeting and deep links: drillside://focus, //checkin, //drill.
struct LauncherEntry: TimelineEntry {
    let date: Date
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry { LauncherEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(LauncherEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        // One entry per hour for the next 12 hours so the greeting follows the day.
        let cal = Calendar.current
        let start = cal.date(bySetting: .minute, value: 0, of: Date()) ?? Date()
        let entries = (0..<12).compactMap { cal.date(byAdding: .hour, value: $0, to: start) }.map { LauncherEntry(date: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

enum LauncherCopy {
    static func greeting(_ date: Date) -> (String, String) {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case 5..<11: return ("Good morning", "Define today’s top 3, then drill in.")
        case 11..<14: return ("Midday check", "One focused block before lunch?")
        case 14..<18: return ("Afternoon push", "Iterate on one small thing.")
        case 18..<22: return ("Evening wind-down", "2-minute check-in: what went well?")
        default: return ("Late night", "Rest is part of the routine.")
        }
    }

    static func isEvening(_ date: Date) -> Bool {
        let h = Calendar.current.component(.hour, from: date)
        return h >= 18 || h < 5
    }
}

struct MiniMole: View {
    var size: CGFloat = 44

    var body: some View {
        let s = size / 44
        ZStack {
            Ellipse().fill(Color(hex: 0x8C5E3B)).frame(width: 30 * s, height: 32 * s).offset(y: 4 * s)
            Ellipse().fill(Color(hex: 0xE6C7A2)).frame(width: 18 * s, height: 17 * s).offset(y: 9 * s)
            HStack(spacing: 7 * s) {
                Circle().fill(Color(hex: 0x2A1C12)).frame(width: 4 * s, height: 4.6 * s)
                Circle().fill(Color(hex: 0x2A1C12)).frame(width: 4 * s, height: 4.6 * s)
            }
            .offset(y: -1 * s)
            Ellipse().fill(Color(hex: 0xF08AA0)).frame(width: 6.5 * s, height: 4.6 * s).offset(y: 3.5 * s)
            Circle().fill(Color(hex: 0xFFC63A)).frame(width: 23 * s, height: 23 * s)
                .mask(Rectangle().frame(width: 23 * s, height: 11.5 * s).offset(y: -5.75 * s))
                .offset(y: -9 * s)
            Capsule().fill(Color(hex: 0xE9A51C)).frame(width: 28 * s, height: 3.4 * s).offset(y: -9 * s)
            Circle().fill(.white).frame(width: 5.6 * s, height: 5.6 * s).offset(y: -15 * s)
        }
        .frame(width: size, height: size)
    }
}

struct LauncherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LauncherEntry

    var body: some View {
        let copy = LauncherCopy.greeting(entry.date)
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "hammer.fill").font(.system(size: 20, weight: .bold))
            }
            .widgetURL(URL(string: "drillside://focus"))
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Label("Drillside", systemImage: "hammer.fill").font(.headline)
                Text(LauncherCopy.isEvening(entry.date) ? "Tap to check in" : "Tap to start focus").font(.caption)
            }
            .widgetURL(URL(string: LauncherCopy.isEvening(entry.date) ? "drillside://checkin" : "drillside://focus"))
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    MiniMole(size: 40)
                    Spacer()
                }
                Text(copy.0).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Image(systemName: LauncherCopy.isEvening(entry.date) ? "book.closed.fill" : "play.fill")
                    Text(LauncherCopy.isEvening(entry.date) ? "Check in" : "Start focus")
                }
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x141826))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.white, in: Capsule())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetURL(URL(string: LauncherCopy.isEvening(entry.date) ? "drillside://checkin" : "drillside://focus"))
        default:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    MiniMole(size: 40)
                    Text(copy.0).font(.system(size: 15, weight: .heavy, design: .rounded))
                    Text(copy.1).font(.system(size: 12)).opacity(0.8).lineLimit(2)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 6) {
                    button("Focus", "play.fill", "drillside://focus", primary: true)
                    button("Check in", "book.closed.fill", "drillside://checkin")
                    button("DRILL", "checkmark.square.fill", "drillside://drill")
                }
                .frame(width: 118)
            }
        }
    }

    private func button(_ title: String, _ icon: String, _ url: String, primary: Bool = false) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(title).font(.system(size: 13, weight: .heavy, design: .rounded))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .foregroundStyle(primary ? Color(hex: 0x141826) : .white)
            .background(primary ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.white.opacity(0.18)), in: Capsule())
        }
    }
}

struct LauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DrillsideLauncher", provider: LauncherProvider()) { entry in
            LauncherWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color(hex: 0xFF9A4D), Color(hex: 0xFF7A2F)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Drillside")
        .description("Start a focus block or check in with one tap.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
