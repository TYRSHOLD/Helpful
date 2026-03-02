import Foundation
import Observation
import FirebaseFirestore
import WidgetKit

@Observable
@MainActor
final class GoalViewModel {

    var goals: [Goal] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private let service = FirestoreService.shared

    var totalSaved: Double { goals.reduce(0) { $0 + $1.currentAmount } }
    var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }

    private func syncWidgetData() {
        // Save featured goal (for non-configured widgets or fallback)
        if let topGoal = goals.first(where: { $0.currentAmount < $0.targetAmount }) ?? goals.first,
           let goalId = topGoal.id {
            WidgetDataManager.saveGoal(
                .init(id: goalId, title: topGoal.title, emoji: topGoal.emoji, current: topGoal.currentAmount, target: topGoal.targetAmount)
            )
        }
        
        // Save full goal list (for widget configuration)
        let goalSnapshots = goals.compactMap { goal -> WidgetDataManager.GoalSnapshot? in
            guard let id = goal.id else { return nil }
            return WidgetDataManager.GoalSnapshot(
                id: id,
                title: goal.title,
                emoji: goal.emoji,
                current: goal.currentAmount,
                target: goal.targetAmount
            )
        }
        WidgetDataManager.saveGoalList(.init(goals: goalSnapshots))
        
        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
    }

    func startListening() {
        listener?.remove()
        do {
            listener = try service.listenToGoals { [weak self] goals in
                Task { @MainActor in
                    self?.goals = goals
                    self?.scheduleGoalReminders()
                    self?.syncWidgetData()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleGoalReminders() {
        for goal in goals {
            guard let id = goal.id else { continue }
            NotificationService.shared.scheduleGoalReminder(
                goalId: id,
                title: goal.title,
                deadline: goal.deadline,
                isComplete: goal.currentAmount >= goal.targetAmount
            )
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func load() async {
        isLoading = true
        do {
            goals = try await service.fetchGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(title: String, emoji: String, targetAmount: Double, deadline: Date) async {
        let goal = Goal(
            title: title,
            emoji: emoji,
            targetAmount: targetAmount,
            currentAmount: 0,
            deadline: deadline
        )
        do {
            try await service.addGoal(goal)
            // Sync widget data immediately after adding goal
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProgress(goal: Goal, newAmount: Double) async {
        guard let id = goal.id else { return }
        do {
            try await service.updateGoalProgress(id: id, currentAmount: newAmount)
            // Sync widget data immediately after updating goal progress
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ goal: Goal) async {
        guard let id = goal.id else {
            print("[GoalVM] Cannot delete: goal.id is nil")
            return
        }
        goals.removeAll { $0.id == id }
        do {
            try await service.deleteGoal(id: id)
            // Sync widget data immediately after deleting goal
            syncWidgetData()
        } catch {
            print("[GoalVM] Delete failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            await load()
        }
    }
}
