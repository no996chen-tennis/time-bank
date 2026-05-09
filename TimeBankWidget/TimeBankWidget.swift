import SwiftUI
import WidgetKit

struct TimeBankWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TimeBankWidgetSnapshot
}

struct TimeBankWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeBankWidgetEntry {
        TimeBankWidgetEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeBankWidgetEntry) -> Void) {
        completion(TimeBankWidgetEntry(date: .now, snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeBankWidgetEntry>) -> Void) {
        let now = Date()
        let entry = TimeBankWidgetEntry(date: now, snapshot: loadSnapshot())
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(6 * 60 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadSnapshot() -> TimeBankWidgetSnapshot {
        TimeBankWidgetSnapshotStore.load() ?? .sample
    }
}

@main
struct TimeBankWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeBankWidget()
    }
}

struct TimeBankWidget: Widget {
    let kind = "TimeBankWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeBankWidgetProvider()) { entry in
            TimeBankWidgetView(entry: entry)
        }
        .configurationDisplayName("时间银行")
        .description("看看今年还剩多少周，以及最重要的时间账户。")
        .supportedFamilies([.accessoryRectangular, .systemMedium])
    }
}

private struct TimeBankWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimeBankWidgetEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenWidgetView(snapshot: entry.snapshot)
                .containerBackground(.clear, for: .widget)
        default:
            HomeScreenMediumWidgetView(snapshot: entry.snapshot)
                .containerBackground(widgetBackground, for: .widget)
        }
    }

    private var widgetBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.95, blue: 0.89),
                Color(red: 0.91, green: 0.86, blue: 0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct LockScreenWidgetView: View {
    let snapshot: TimeBankWidgetSnapshot

    private var primaryDimension: TimeBankWidgetDimensionSnapshot? {
        snapshot.dimensions.first
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("今年余额")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(snapshot.yearBalanceWeeks)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("周")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .frame(width: 72, alignment: .leading)

            Divider()
                .opacity(0.5)

            VStack(alignment: .leading, spacing: 3) {
                if let primaryDimension {
                    Text("\(primaryDimension.name) \(hoursShort(primaryDimension.yearConsumeHours)) · \(primaryDimension.subtitle)")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Text(lockCopy)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }

    private var lockCopy: String {
        if let primaryDimension {
            return primaryDimension.lastMoment?.title ?? "今年还有一些时间，可以慢慢过。"
        }
        return snapshot.topText
    }
}

private struct HomeScreenMediumWidgetView: View {
    let snapshot: TimeBankWidgetSnapshot

    private var dimensions: [TimeBankWidgetDimensionSnapshot] {
        Array(snapshot.dimensions.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今年余额")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(snapshot.yearBalanceWeeks)")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("周")
                            .font(.system(size: 18, weight: .medium))
                    }
                }

                Spacer(minLength: 8)

                Text(snapshot.topText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .frame(maxWidth: 138, alignment: .trailing)
            }

            HStack(spacing: 8) {
                ForEach(dimensions) { dimension in
                    DimensionMiniCard(dimension: dimension)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 13, weight: .semibold))
                Text("已存入")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text("\(snapshot.storedMomentCountTotal) 个瞬间")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.09))
    }
}

private struct DimensionMiniCard: View {
    let dimension: TimeBankWidgetDimensionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle()
                    .fill(widgetColor(for: dimension.colorKey))
                    .frame(width: 7, height: 7)

                Text(dimension.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(hoursShort(dimension.yearConsumeHours))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Text(dimension.subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private func hoursShort(_ hours: Double) -> String {
    let rounded = max(0, Int(hours.rounded()))
    if rounded < 10_000 {
        return "\(rounded.formatted(.number.grouping(.automatic)))h"
    }

    let wan = Double(rounded) / 10_000
    if wan < 10 {
        return "\(String(format: "%.1f", wan))万h"
    }
    return "\(Int(wan.rounded()))万h"
}

private func widgetColor(for key: String) -> Color {
    switch key {
    case "rose":
        return Color(red: 0.75, green: 0.42, blue: 0.41)
    case "warm":
        return Color(red: 0.85, green: 0.60, blue: 0.32)
    case "lavender":
        return Color(red: 0.55, green: 0.47, blue: 0.66)
    case "sage":
        return Color(red: 0.32, green: 0.47, blue: 0.38)
    case "sky":
        return Color(red: 0.31, green: 0.50, blue: 0.61)
    case "peach":
        return Color(red: 0.84, green: 0.51, blue: 0.38)
    case "coral":
        return Color(red: 0.86, green: 0.46, blue: 0.37)
    case "mint":
        return Color(red: 0.34, green: 0.55, blue: 0.46)
    case "denim":
        return Color(red: 0.25, green: 0.40, blue: 0.56)
    case "mauve":
        return Color(red: 0.56, green: 0.38, blue: 0.47)
    default:
        return Color.secondary
    }
}

#Preview(as: .systemMedium) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample)
}

#Preview(as: .accessoryRectangular) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample)
}
