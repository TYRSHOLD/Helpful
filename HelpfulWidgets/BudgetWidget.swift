import WidgetKit
import SwiftUI

struct BudgetEntry: TimelineEntry {
    let date: Date
    let month: String
    let total: Double
    let spent: Double
    var remaining: Double { max(total - spent, 0) }
    var progress: Double { total > 0 ? min(spent / total, 1) : 0 }
}

struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: .now, month: "February", total: 500, spent: 320)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> BudgetEntry {
        guard let defaults = UserDefaults(suiteName: "group.com.helpful.shared"),
              let data = defaults.data(forKey: "widget_budget"),
              let snapshot = try? JSONDecoder().decode(BudgetSnapshotWidget.self, from: data)
        else {
            return BudgetEntry(date: .now, month: "—", total: 0, spent: 0)
        }
        return BudgetEntry(date: .now, month: snapshot.month, total: snapshot.total, spent: snapshot.spent)
    }
}

private struct BudgetSnapshotWidget: Codable {
    let month: String
    let total: Double
    let spent: Double
}

struct BudgetWidgetView: View {
    let entry: BudgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.teal)
                Text(entry.month)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Text(currencyString(entry.remaining))
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("left of \(currencyString(entry.total))")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ProgressView(value: entry.progress)
                .tint(entry.progress > 0.85 ? .red : .teal)
        }
        .padding()
    }

    private func currencyString(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

struct BudgetWidget: Widget {
    let kind = "BudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "helpful://open?tab=budgets"))
        }
        .configurationDisplayName("Budget")
        .description("See your current month's remaining budget.")
        .supportedFamilies([.systemSmall])
    }
}
