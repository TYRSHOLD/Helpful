import SwiftUI

struct RecurringTransactionsView: View {

    @Environment(TransactionViewModel.self) private var txnVM

    @State private var selectedDate = Date()

    private var calendar = Calendar.current

    private var recurring: [Transaction] {
        txnVM.transactions
            .filter { $0.isRecurring }
            .sorted { $0.date > $1.date }
    }

    private var recurringForSelectedDate: [Transaction] {
        recurring.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var hasDateFilter: Bool {
        // Only treat as "filtered" when the selected day isn't today and
        // there are any matches for that specific day.
        !calendar.isDateInToday(selectedDate) && !recurringForSelectedDate.isEmpty
    }

    private var listData: [Transaction] {
        hasDateFilter ? recurringForSelectedDate : recurring
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recurring calendar")
                        .font(.headline)

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    if hasDateFilter {
                        Text("Showing recurring items for \(selectedDate.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tap a date to focus on the recurring items that land on that day.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                Text("Recurring transactions are created automatically based on the “Repeat this transaction” option when you add a transaction.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if listData.isEmpty {
                ContentUnavailableView(
                    "No Recurring Transactions",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Add a transaction and turn on “Repeat this transaction” to see it here.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(listData) { txn in
                    TransactionRow(transaction: txn)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await txnVM.delete(txn) }
                            } label: {
                                Label("Stop", systemImage: "xmark.circle.fill")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await txnVM.load()
        }
    }
}

