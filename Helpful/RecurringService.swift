import Foundation

@MainActor
final class RecurringService {

    static let shared = RecurringService()
    private let service = FirestoreService.shared
    private init() {}

    func processRecurring() async {
        do {
            let recurring = try await service.fetchRecurringTransactions()
            let allTxns = try await service.fetchTransactions()
            let cal = Calendar.current

            for txn in recurring {
                guard let interval = txn.recurrenceInterval else { continue }
                let (component, value) = interval.calendarComponent
                guard let nextDate = cal.date(byAdding: component, value: value, to: txn.date) else { continue }

                guard nextDate <= Date() else { continue }

                let alreadyExists = allTxns.contains { other in
                    other.category == txn.category &&
                    other.amount == txn.amount &&
                    other.note == txn.note &&
                    cal.isDate(other.date, equalTo: nextDate, toGranularity: component == .month ? .month : .weekOfYear)
                }

                guard !alreadyExists else { continue }

                let newTxn = Transaction(
                    amount: txn.amount,
                    category: txn.category,
                    note: txn.note,
                    date: nextDate,
                    isRecurring: true,
                    recurrenceInterval: txn.recurrenceInterval
                )

                try await service.addTransaction(newTxn)
            }
        } catch {
            print("[RecurringService] Error processing recurring transactions: \(error)")
        }
    }
}
