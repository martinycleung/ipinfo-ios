import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct IPInfoProvider: TimelineProvider {
    func placeholder(in context: Context) -> IPInfoEntry {
        IPInfoEntry(date: Date(), ip: "192.168.1.1", location: "Loading...", organization: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (IPInfoEntry) -> Void) {
        let entry = IPInfoEntry(
            date: Date(),
            ip: "8.8.8.8",
            location: "Mountain View, CA",
            organization: "Google"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IPInfoEntry>) -> Void) {
        Task {
            do {
                let ipInfo = try await fetchMyIP()
                let entry = IPInfoEntry(
                    date: Date(),
                    ip: ipInfo.ip,
                    location: ipInfo.locationString,
                    organization: ipInfo.org
                )

                // Refresh every 30 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = IPInfoEntry(
                    date: Date(),
                    ip: "Error",
                    location: "Unable to fetch IP",
                    organization: nil
                )
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }

    private func fetchMyIP() async throws -> IPInfoData {
        guard let url = URL(string: "https://ipapi.co/json/") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(IPInfoData.self, from: data)
    }
}

// MARK: - Data Models

struct IPInfoData: Codable {
    let ip: String
    let city: String?
    let region: String?
    let countryName: String?
    let org: String?

    enum CodingKeys: String, CodingKey {
        case ip, city, region, org
        case countryName = "country_name"
    }

    var locationString: String {
        var parts: [String] = []
        if let city = city { parts.append(city) }
        if let region = region { parts.append(region) }
        return parts.isEmpty ? "Unknown" : parts.joined(separator: ", ")
    }
}

struct IPInfoEntry: TimelineEntry {
    let date: Date
    let ip: String
    let location: String
    let organization: String?
}

// MARK: - Widget Views

struct IPInfoWidgetEntryView: View {
    var entry: IPInfoProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: IPInfoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
                Text("My IP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.ip)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(entry.location)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: IPInfoEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("My IP Address")
                        .font(.headline)
                }

                Spacer()

                Text(entry.ip)
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.bold)

                Text(entry.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let org = entry.organization {
                    Text(org)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack {
                Image(systemName: "location.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue.opacity(0.3))
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AccessoryCircularView: View {
    let entry: IPInfoEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "globe")
                    .font(.caption)
                Text(shortIP(entry.ip))
                    .font(.system(.caption2, design: .monospaced))
                    .minimumScaleFactor(0.5)
            }
        }
    }

    private func shortIP(_ ip: String) -> String {
        let parts = ip.split(separator: ".")
        if parts.count >= 2 {
            return "\(parts[0]).\(parts[1])..."
        }
        return ip
    }
}

struct AccessoryRectangularView: View {
    let entry: IPInfoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "globe")
                Text("My IP")
                    .font(.headline)
            }
            Text(entry.ip)
                .font(.system(.body, design: .monospaced))
            Text(entry.location)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Configuration

struct IPInfoWidget: Widget {
    let kind: String = "IPInfoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IPInfoProvider()) { entry in
            IPInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simple IP Info")
        .description("View your current IP address and location")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Widget Bundle

@main
struct IPInfoWidgetBundle: WidgetBundle {
    var body: some Widget {
        IPInfoWidget()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    IPInfoWidget()
} timeline: {
    IPInfoEntry(date: .now, ip: "203.45.67.89", location: "Sydney, NSW", organization: "Telstra")
}

#Preview(as: .systemMedium) {
    IPInfoWidget()
} timeline: {
    IPInfoEntry(date: .now, ip: "203.45.67.89", location: "Sydney, NSW", organization: "Telstra")
}
