import WidgetKit
import SwiftUI

struct SpendingEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
    let recentItems: [SpendingItemWidget]
}

struct SpendingItemWidget: Codable {
    let category: String
    let amount: Double
    let note: String
}

private struct SpendingSnapshotWidget: Codable {
    let todayTotal: Double
    let recentItems: [SpendingItemWidget]
}

struct SpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingEntry {
        SpendingEntry(date: .now, todayTotal: 45.50, recentItems: [
            .init(category: "Food", amount: 12.50, note: "Lunch"),
            .init(category: "Transport", amount: 8.00, note: "Bus"),
            .init(category: "Shopping", amount: 25.00, note: "Books")
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendingEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> SpendingEntry {
        guard let defaults = UserDefaults(suiteName: "group.com.helpful.shared"),
              let data = defaults.data(forKey: "widget_spending"),
              let snapshot = try? JSONDecoder().decode(SpendingSnapshotWidget.self, from: data)
        else {
            return SpendingEntry(date: .now, todayTotal: 0, recentItems: [])
        }
        return SpendingEntry(
            date: .now,
            todayTotal: snapshot.todayTotal,
            recentItems: snapshot.recentItems.map { .init(category: $0.category, amount: $0.amount, note: $0.note) }
        )
    }
}

struct SpendingWidgetView: View {
    let entry: SpendingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(.orange)
                Text("Today's Spending")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currencyString(entry.todayTotal))
                    .font(.subheadline.bold())
            }

            if entry.recentItems.isEmpty {
                Text("No transactions yet today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.recentItems.prefix(3), id: \.category) { item in
                    HStack {
                        Text(item.category)
                            .font(.caption)
                        if !item.note.isEmpty {
                            Text("· \(item.note)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(currencyString(item.amount))
                            .font(.caption.bold())
                    }
                }
            }
        }
        .padding()
    }

    private func currencyString(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: v)) ?? "$0.00"
    }
}

struct SpendingWidget: Widget {
    let kind = "SpendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingProvider()) { entry in
            SpendingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "helpful://open?tab=spending"))
        }
        .configurationDisplayName("Spending")
        .description("Today's spending and recent transactions.")
        .supportedFamilies([.systemMedium])
    }
}
