import Foundation
import Observation

@Observable
@MainActor
final class AIInsightsViewModel {

    var insights: [AIInsight] = []
    var summaryText: String?
    var isLoading = false
    var errorMessage: String?
    var lastGeneratedAt: Date?

    private let service = AIService.shared

    func refreshIfNeeded(
        transactions: [Transaction],
        budgets: [Budget],
        goals: [Goal],
        force: Bool = false
    ) async {
        if !force, let last = lastGeneratedAt, Date().timeIntervalSince(last) < 60 * 60 {
            return
        }
        await generate(transactions: transactions, budgets: budgets, goals: goals)
    }

    func generate(
        transactions: [Transaction],
        budgets: [Budget],
        goals: [Goal]
    ) async {
        guard !transactions.isEmpty || !budgets.isEmpty || !goals.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        let contextText = buildContextDescription(
            transactions: transactions,
            budgets: budgets,
            goals: goals
        )

        do {
            async let insightsResult = service.generateInsights(contextDescription: contextText)
            async let summaryResult = service.generateSummary(contextDescription: contextText)

            let (newInsights, newSummary) = try await (insightsResult, summaryResult)

            insights = newInsights
            summaryText = newSummary.trimmingCharacters(in: .whitespacesAndNewlines)
            lastGeneratedAt = Date()
        } catch {
            errorMessage = AIService.formatGenerateContentError(error)
        }

        isLoading = false
    }

    private func buildContextDescription(
        transactions: [Transaction],
        budgets: [Budget],
        goals: [Goal]
    ) -> String {
        let cal = Calendar.current
        let now = Date()

        let currentMonthTxns = transactions.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        let income = currentMonthTxns
            .filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amount }

        let expenses = currentMonthTxns
            .filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }

        let net = income - expenses

        let groupedCategories = Dictionary(grouping: currentMonthTxns.filter { $0.kind == .expense }) {
            $0.parsedCategory
        }
        let categoryLines = groupedCategories
            .map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
            .map { "\($0.category.rawValue): \($0.amount)" }
            .joined(separator: ", ")

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let currentMonthName = formatter.string(from: now)

        let currentBudget = budgets.first { $0.month == currentMonthName }

        let budgetLine: String
        if let budget = currentBudget {
            budgetLine = "Budget for \(budget.month): total \(budget.total), spent \(budget.spent), remaining \(budget.remaining)."
        } else {
            budgetLine = "No explicit budget set for \(currentMonthName)."
        }

        let goalLines: String
        if goals.isEmpty {
            goalLines = "No savings goals set."
        } else {
            let df = DateFormatter()
            df.dateStyle = .medium
            goalLines = goals.prefix(5).map {
                "Goal \"\($0.title)\": \($0.currentAmount) of \($0.targetAmount) saved, deadline \(df.string(from: $0.deadline))."
            }.joined(separator: " ")
        }

        return """
        Month: \(currentMonthName)
        Income this month: \(income)
        Expenses this month: \(expenses)
        Net income this month: \(net)

        Spending by category this month:
        \(categoryLines.isEmpty ? "No categorized spending yet." : categoryLines)

        \(budgetLine)

        Goals:
        \(goalLines)
        """
    }
}

