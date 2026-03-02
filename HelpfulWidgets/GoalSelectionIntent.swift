import WidgetKit
import AppIntents

struct GoalSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Goal" }
    static var description: IntentDescription { "Choose which goal to display in the widget." }
    
    @Parameter(title: LocalizedStringResource("Goal"))
    var selectedGoal: GoalEntity?
    
    init() {}
    
    init(selectedGoal: GoalEntity?) {
        self.selectedGoal = selectedGoal
    }
}

struct GoalQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GoalEntity] {
        guard let defaults = UserDefaults(suiteName: "group.com.helpful.shared"),
              let data = defaults.data(forKey: "widget_goal_list"),
              let goalList = try? JSONDecoder().decode(GoalListSnapshotForIntent.self, from: data) else {
            return []
        }
        // Filter goals by the provided identifiers
        return goalList.goals
            .filter { identifiers.contains($0.id) }
            .map { goal in
                GoalEntity(id: goal.id, displayString: "\(goal.emoji) \(goal.title)")
            }
    }
    
    func suggestedEntities() async throws -> [GoalEntity] {
        guard let defaults = UserDefaults(suiteName: "group.com.helpful.shared"),
              let data = defaults.data(forKey: "widget_goal_list"),
              let goalList = try? JSONDecoder().decode(GoalListSnapshotForIntent.self, from: data) else {
            return []
        }
        // Return all goals as suggestions
        return goalList.goals.map { goal in
            GoalEntity(id: goal.id, displayString: "\(goal.emoji) \(goal.title)")
        }
    }
}

struct GoalEntity: AppEntity {
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: displayString))
    }
    
    let displayString: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("Goal"))
    }
    
    static var defaultQuery = GoalQuery()
}

private struct GoalListSnapshotForIntent: Codable {
    let goals: [GoalSnapshotForIntent]
}

private struct GoalSnapshotForIntent: Codable {
    let id: String
    let title: String
    let emoji: String
    let current: Double
    let target: Double
}
