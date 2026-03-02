import WidgetKit
import SwiftUI

struct GoalEntry: TimelineEntry {
    let date: Date
    let title: String
    let emoji: String
    let current: Double
    let target: Double
    let goalId: String?
    var progress: Double { target > 0 ? min(current / target, 1) : 0 }
}

private struct GoalSnapshotWidget: Codable {
    let id: String
    let title: String
    let emoji: String
    let current: Double
    let target: Double
}

private struct GoalListSnapshotWidget: Codable {
    let goals: [GoalSnapshotWidget]
}

struct GoalProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(date: .now, title: "New Laptop", emoji: "💻", current: 650, target: 1200, goalId: nil)
    }

    func snapshot(for configuration: GoalSelectionIntent, in context: Context) async -> GoalEntry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: GoalSelectionIntent, in context: Context) async -> Timeline<GoalEntry> {
        let entry = makeEntry(for: configuration)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func makeEntry(for configuration: GoalSelectionIntent) -> GoalEntry {
        let selectedGoalId = configuration.selectedGoal?.id
        
        // Try to load goal list first
        if let selectedGoalId = selectedGoalId,
           let defaults = UserDefaults(suiteName: "group.com.helpful.shared"),
           let listData = defaults.data(forKey: "widget_goal_list"),
           let goalList = try? JSONDecoder().decode(GoalListSnapshotWidget.self, from: listData),
           let selectedGoal = goalList.goals.first(where: { $0.id == selectedGoalId }) {
            return GoalEntry(
                date: .now,
                title: selectedGoal.title,
                emoji: selectedGoal.emoji,
                current: selectedGoal.current,
                target: selectedGoal.target,
                goalId: selectedGoalId
            )
        }
        
        // Fallback to default featured goal
        guard let defaults = UserDefaults(suiteName: "group.com.helpful.shared"),
              let data = defaults.data(forKey: "widget_goal"),
              let snapshot = try? JSONDecoder().decode(GoalSnapshotWidget.self, from: data)
        else {
            return GoalEntry(date: .now, title: "No Goal", emoji: "🎯", current: 0, target: 0, goalId: nil)
        }
        return GoalEntry(
            date: .now,
            title: snapshot.title,
            emoji: snapshot.emoji,
            current: snapshot.current,
            target: snapshot.target,
            goalId: snapshot.id
        )
    }
}

struct GoalWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        VStack(spacing: 10) {
            Text(entry.emoji)
                .font(.system(size: 30))

            Text(entry.title)
                .font(.caption.bold())
                .lineLimit(1)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(entry.progress * 100))%")
                    .font(.caption2.bold())
            }
            .frame(width: 50, height: 50)

            Text("\(currencyString(entry.current)) / \(currencyString(entry.target))")
                .font(.caption2)
                .foregroundStyle(.secondary)
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

struct GoalWidget: Widget {
    let kind = "GoalWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GoalSelectionIntent.self, provider: GoalProvider()) { entry in
            GoalWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "helpful://open?tab=goals"))
        }
        .configurationDisplayName("Goal")
        .description("Track your savings goal progress.")
        .supportedFamilies([.systemSmall])
    }
}
