import Foundation
import Observation
import FirebaseFirestore
import WidgetKit

@Observable
@MainActor
final class BudgetViewModel {

    var budgets: [Budget] = []
    var isLoading = false
    var errorMessage: String?
    var rolloverMessage: String?

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private let service = FirestoreService.shared

    var totalBudget: Double { budgets.reduce(0) { $0 + $1.total } }
    var totalSpent: Double { budgets.reduce(0) { $0 + $1.spent } }

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private func syncWidgetData() {
        if let budget = budgets.first(where: { $0.month == currentMonthName }) {
            WidgetDataManager.saveBudget(
                .init(month: budget.month, total: budget.total, spent: budget.spent)
            )
            WidgetCenter.shared.reloadTimelines(ofKind: "BudgetWidget")
        }
    }

    func startListening() {
        listener?.remove()
        do {
            listener = try service.listenToBudgets { [weak self] budgets in
                Task { @MainActor in
                    self?.budgets = budgets
                    self?.syncWidgetData()
                    await self?.checkAndRollover()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var previousMonthName: String {
        let cal = Calendar.current
        guard let lastMonth = cal.date(byAdding: .month, value: -1, to: Date()) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: lastMonth)
    }

    @ObservationIgnored private var didCheckRollover = false

    func checkAndRollover() async {
        guard !didCheckRollover else { return }
        didCheckRollover = true

        let hasCurrentMonth = budgets.contains { $0.month == currentMonthName }
        guard !hasCurrentMonth else { return }

        let prev = previousMonthName
        guard let previousBudget = budgets.first(where: { $0.month == prev }) else { return }

        await add(month: currentMonthName, total: previousBudget.total)
        rolloverMessage = "Budget rolled over from \(prev)"

        try? await Task.sleep(for: .seconds(5))
        rolloverMessage = nil
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func load() async {
        isLoading = true
        do {
            budgets = try await service.fetchBudgets()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(month: String, total: Double) async {
        let budget = Budget(
            month: month,
            total: total,
            spent: 0,
            createdAt: Date()
        )
        do {
            try await service.addBudget(budget)
            // Sync widget data immediately after adding budget
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ budget: Budget) async {
        guard let id = budget.id else {
            print("[BudgetVM] Cannot delete: budget.id is nil")
            return
        }
        budgets.removeAll { $0.id == id }
        do {
            try await service.deleteBudget(id: id)
        } catch {
            print("[BudgetVM] Delete failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            await load()
        }
    }

    func addSpending(amount: Double) async {
        guard let budget = budgets.first(where: { $0.month == currentMonthName }),
              let id = budget.id else { return }
        let newSpent = budget.spent + amount
        do {
            try await service.updateBudgetSpent(id: id, spent: newSpent)
            NotificationService.shared.scheduleBudgetWarning(
                budgetMonth: budget.month,
                spent: newSpent,
                total: budget.total
            )
            // Sync widget data immediately after adding spending
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func subtractSpending(amount: Double) async {
        guard let budget = budgets.first(where: { $0.month == currentMonthName }),
              let id = budget.id else { return }
        let newSpent = max(budget.spent - amount, 0)
        do {
            try await service.updateBudgetSpent(id: id, spent: newSpent)
            // Sync widget data immediately after subtracting spending
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
