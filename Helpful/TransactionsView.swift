import SwiftUI

struct TransactionsView: View {

    @Environment(TransactionViewModel.self) var vm
    @Environment(BudgetViewModel.self) var budgetVM
    @State private var showingAdd = false
    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""
    @State private var filterCategory: TransactionCategory?

    private struct MonthGroup: Identifiable {
        let id = UUID()
        let month: String
        let total: Double
        let transactions: [Transaction]
    }

    private var filteredTransactions: [Transaction] {
        vm.transactions.filter { txn in
            let matchesSearch = searchText.isEmpty ||
                txn.parsedCategory.rawValue.localizedCaseInsensitiveContains(searchText) ||
                txn.note.localizedCaseInsensitiveContains(searchText) ||
                String(format: "%.2f", txn.amount).contains(searchText)
            let matchesCategory = filterCategory == nil || txn.parsedCategory == filterCategory
            return matchesSearch && matchesCategory
        }
    }

    private var monthGroups: [MonthGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: filteredTransactions) { txn in
            formatter.string(from: txn.date)
        }
        return grouped.map { key, value in
            let total = value.reduce(0) { $0 + (txnIsIncome($1) ? -$1.amount : $1.amount) }
            return MonthGroup(month: key, total: total, transactions: value.sorted { $0.date > $1.date })
        }
        .sorted { $0.month > $1.month }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                searchBar

                if vm.transactions.isEmpty && !vm.isLoading {
                    List {
                        ContentUnavailableView(
                            "No Transactions",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Tap + to log your first transaction.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                } else {
                    List {
                        ForEach(monthGroups) { group in
                            Section {
                                ForEach(group.transactions) { txn in
                                    transactionRow(txn)
                                }
                            } header: {
                                HStack {
                                    Text(group.month)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(currencyString(group.total))
                                        .font(.footnote.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }

            addButton
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All Categories") { filterCategory = nil }
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        Button {
                            filterCategory = cat
                        } label: {
                            Label(cat.rawValue, systemImage: cat.icon)
                        }
                    }
                } label: {
                    Image(systemName: filterCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareCSV()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddTransactionView()
        }
        .sheet(item: $selectedTransaction) { txn in
            TransactionDetailView(transaction: txn)
        }
        .refreshable {
            await vm.load()
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search my transactions", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(10)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding([.horizontal, .top])
    }

    private var addButton: some View {
        Button {
            showingAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppGradients.primary)
                .clipShape(Circle())
                .shadow(color: AppColors.coral.opacity(0.4), radius: 8, y: 4)
        }
        .padding(20)
    }

    private func transactionRow(_ txn: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: txn.parsedCategory.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(txn.parsedCategory.color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(txn.note.isEmpty ? txn.parsedCategory.rawValue : txn.note)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text(txn.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountString(for: txn))
                    .font(.subheadline.bold())
                    .foregroundStyle(txn.kind == .income ? AppColors.green : AppColors.coral)
                Text(txn.kind == .income ? "Income" : "Expense")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { selectedTransaction = txn }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    if txn.kind == .expense {
                        await budgetVM.subtractSpending(amount: txn.amount)
                    }
                    await vm.delete(txn)
                }
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }

    private func amountString(for txn: Transaction) -> String {
        let prefix = txn.kind == .income ? "+" : "-"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let base = formatter.string(from: NSNumber(value: txn.amount)) ?? "$0.00"
        return prefix + base
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func txnIsIncome(_ txn: Transaction) -> Bool {
        txn.kind == .income
    }

    private func shareCSV() {
        let header = "Date,Type,Category,Note,Amount\n"
        let rows = filteredTransactions.map { txn -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let dateString = formatter.string(from: txn.date)
            return "\"\(dateString)\",\"\(txn.kind.rawValue)\",\"\(txn.parsedCategory.rawValue)\",\"\(txn.note)\",\(txn.amount)"
        }
        let csv = header + rows.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Transactions.csv")
        try? csv.data(using: .utf8)?.write(to: tempURL)
        let activity = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activity, animated: true)
    }
}
