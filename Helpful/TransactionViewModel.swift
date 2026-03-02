import Foundation
import Observation
import FirebaseFirestore
import WidgetKit

@Observable
@MainActor
final class TransactionViewModel {

    var transactions: [Transaction] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private let service = FirestoreService.shared

    var totalSpent: Double { transactions.reduce(0) { $0 + $1.amount } }

    var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    var groupedByDate: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: transactions) { formatter.string(from: $0.date) }
        return grouped.sorted { lhs, rhs in
            guard let l = lhs.value.first?.date, let r = rhs.value.first?.date else { return false }
            return l > r
        }
    }

    private func syncWidgetData() {
        let cal = Calendar.current
        let todayTxns = transactions.filter { cal.isDateInToday($0.date) }
        let todayTotal = todayTxns.reduce(0) { $0 + $1.amount }
        let recent = Array(transactions.prefix(3)).map {
            WidgetDataManager.SpendingItem(category: $0.category, amount: $0.amount, note: $0.note)
        }
        WidgetDataManager.saveSpending(.init(todayTotal: todayTotal, recentItems: recent))
        WidgetCenter.shared.reloadTimelines(ofKind: "SpendingWidget")
    }

    func startListening() {
        listener?.remove()
        do {
            listener = try service.listenToTransactions { [weak self] txns in
                Task { @MainActor in
                    self?.transactions = txns
                    self?.syncWidgetData()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func load() async {
        isLoading = true
        do {
            transactions = try await service.fetchTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(
        amount: Double,
        category: TransactionCategory,
        note: String,
        receiptURL: String? = nil,
        isRecurring: Bool = false,
        recurrenceInterval: RecurrenceInterval? = nil,
        kind: TransactionKind = .expense,
        tags: [String] = []
    ) async {
        let transaction = Transaction(
            amount: amount,
            category: category.rawValue,
            note: note,
            date: Date(),
            receiptURL: receiptURL,
            isRecurring: isRecurring,
            recurrenceInterval: recurrenceInterval,
            kind: kind,
            tags: tags
        )
        do {
            try await service.addTransaction(transaction)
            // Sync widget data immediately after adding transaction
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ transaction: Transaction) async {
        guard let id = transaction.id else {
            print("[TransactionVM] Cannot delete: transaction.id is nil")
            return
        }
        transactions.removeAll { $0.id == id }
        do {
            try await service.deleteTransaction(id: id)
            // Sync widget data immediately after deleting transaction
            syncWidgetData()
        } catch {
            print("[TransactionVM] Delete failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            await load()
        }
    }
}
