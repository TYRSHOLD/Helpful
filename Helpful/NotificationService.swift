import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("[NotificationService] Permission error: \(error)")
            return false
        }
    }

    // MARK: - Budget Warning (80% threshold)

    func scheduleBudgetWarning(budgetMonth: String, spent: Double, total: Double) {
        guard total > 0 else { return }
        let pct = spent / total
        guard pct >= 0.8 else { return }

        let id = "budget-warning-\(budgetMonth)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.body = "You've used \(Int(pct * 100))% of your \(budgetMonth) budget. Consider slowing down!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Goal Deadline Reminder (3 days before)

    func scheduleGoalReminder(goalId: String, title: String, deadline: Date, isComplete: Bool) {
        let id = "goal-reminder-\(goalId)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard !isComplete else { return }

        let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: deadline) ?? deadline
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Goal Reminder"
        content.body = "\"\(title)\" is due in 3 days. Keep it up!"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Weekly Summary (Sunday 6pm)

    func scheduleWeeklySummary() {
        let id = "weekly-summary"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Summary"
        content.body = "Check your spending insights and see how you did this week!"
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
