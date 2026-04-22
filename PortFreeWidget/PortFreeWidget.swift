import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PortFreeEntry: TimelineEntry {
    let date: Date
    let ports: [PortFreeShared.PortEntry]
    let lastUpdated: Date?
}

// MARK: - Timeline Provider

struct PortFreeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PortFreeEntry {
        PortFreeEntry(date: .now, ports: [
            .init(port: 3000, processName: "node", pid: 1234, user: "dev"),
            .init(port: 8080, processName: "java", pid: 5678, user: "dev"),
            .init(port: 5173, processName: "vite", pid: 9012, user: "dev"),
        ], lastUpdated: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PortFreeEntry) -> Void) {
        let entry = PortFreeEntry(
            date: .now,
            ports: PortFreeShared.loadPorts(),
            lastUpdated: PortFreeShared.lastUpdated()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PortFreeEntry>) -> Void) {
        let entry = PortFreeEntry(
            date: .now,
            ports: PortFreeShared.loadPorts(),
            lastUpdated: PortFreeShared.lastUpdated()
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View

struct PortFreeWidgetSmallView: View {
    let entry: PortFreeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.circle.fill")
                    .foregroundStyle(.orange)
                Text("PortFree")
                    .font(.caption.weight(.bold))
            }

            if entry.ports.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("No ports")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                Text("\(entry.ports.count) listening")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.orange)

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entry.ports.prefix(3), id: \.port) { port in
                        HStack(spacing: 4) {
                            Circle().fill(.orange).frame(width: 4, height: 4)
                            Text("\(port.port)")
                                .font(.caption2.monospacedDigit().weight(.medium))
                            Text(port.processName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if entry.ports.count > 3 {
                        Text("+\(entry.ports.count - 3) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct PortFreeWidgetMediumView: View {
    let entry: PortFreeEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: summary
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.circle.fill")
                        .foregroundStyle(.orange)
                    Text("PortFree")
                        .font(.caption.weight(.bold))
                }

                if entry.ports.isEmpty {
                    Text("0")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("All clear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(entry.ports.count)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("listening")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let lastUpdated = entry.lastUpdated {
                    Text(lastUpdated, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minWidth: 80)

            // Right: port list
            if !entry.ports.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.ports.prefix(6), id: \.port) { port in
                        HStack(spacing: 6) {
                            Text("\(port.port)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .frame(width: 44, alignment: .trailing)
                            Text(port.processName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    if entry.ports.count > 6 {
                        Text("+\(entry.ports.count - 6) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 50)
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct PortFreeWidget: Widget {
    let kind: String = "PortFreeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortFreeProvider()) { entry in
            PortFreeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Port Monitor")
        .description("View listening ports at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PortFreeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PortFreeEntry

    var body: some View {
        switch family {
        case .systemSmall:
            PortFreeWidgetSmallView(entry: entry)
        case .systemMedium:
            PortFreeWidgetMediumView(entry: entry)
        default:
            PortFreeWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct PortFreeWidgetBundle: WidgetBundle {
    var body: some Widget {
        PortFreeWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PortFreeWidget()
} timeline: {
    PortFreeEntry(date: .now, ports: [
        .init(port: 3000, processName: "node", pid: 1234, user: "dev"),
        .init(port: 8080, processName: "java", pid: 5678, user: "dev"),
        .init(port: 5173, processName: "vite", pid: 9012, user: "dev"),
        .init(port: 5500, processName: "Live Server", pid: 3456, user: "dev"),
    ], lastUpdated: .now)
}

#Preview(as: .systemMedium) {
    PortFreeWidget()
} timeline: {
    PortFreeEntry(date: .now, ports: [
        .init(port: 3000, processName: "node", pid: 1234, user: "dev"),
        .init(port: 8080, processName: "java", pid: 5678, user: "dev"),
        .init(port: 5173, processName: "vite", pid: 9012, user: "dev"),
        .init(port: 5500, processName: "Live Server", pid: 3456, user: "dev"),
        .init(port: 9000, processName: "webpack", pid: 7890, user: "dev"),
    ], lastUpdated: .now)
}
