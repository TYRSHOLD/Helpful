import Foundation

struct WidgetDataManager {
    static let suiteName = "group.com.helpful.shared"

    static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Budget Data

    struct BudgetSnapshot: Codable {
        let month: String
        let total: Double
        let spent: Double
        var remaining: Double { max(total - spent, 0) }
        var progress: Double { total > 0 ? min(spent / total, 1) : 0 }
    }

    static func saveBudget(_ snapshot: BudgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        shared?.set(data, forKey: "widget_budget")
        shared?.synchronize() // Ensure data is persisted immediately
    }

    static func loadBudget() -> BudgetSnapshot? {
        guard let data = shared?.data(forKey: "widget_budget") else { return nil }
        return try? JSONDecoder().decode(BudgetSnapshot.self, from: data)
    }

    // MARK: - Spending Data

    struct SpendingSnapshot: Codable {
        let todayTotal: Double
        let recentItems: [SpendingItem]
    }

    struct SpendingItem: Codable {
        let category: String
        let amount: Double
        let note: String
    }

    static func saveSpending(_ snapshot: SpendingSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        shared?.set(data, forKey: "widget_spending")
        shared?.synchronize() // Ensure data is persisted immediately
    }

    static func loadSpending() -> SpendingSnapshot? {
        guard let data = shared?.data(forKey: "widget_spending") else { return nil }
        return try? JSONDecoder().decode(SpendingSnapshot.self, from: data)
    }

    // MARK: - Goal Data

    struct GoalSnapshot: Codable {
        let id: String
        let title: String
        let emoji: String
        let current: Double
        let target: Double
        var progress: Double { target > 0 ? min(current / target, 1) : 0 }
    }

    static func saveGoal(_ snapshot: GoalSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        shared?.set(data, forKey: "widget_goal")
        shared?.synchronize() // Ensure data is persisted immediately
    }

    static func loadGoal() -> GoalSnapshot? {
        guard let data = shared?.data(forKey: "widget_goal") else { return nil }
        return try? JSONDecoder().decode(GoalSnapshot.self, from: data)
    }

    // MARK: - Goal List (for widget configuration)

    struct GoalListSnapshot: Codable {
        let goals: [GoalSnapshot]
    }

    static func saveGoalList(_ snapshot: GoalListSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        shared?.set(data, forKey: "widget_goal_list")
        shared?.synchronize() // Ensure data is persisted immediately
    }

    static func loadGoalList() -> GoalListSnapshot? {
        guard let data = shared?.data(forKey: "widget_goal_list") else { return nil }
        return try? JSONDecoder().decode(GoalListSnapshot.self, from: data)
    }
}
