import SwiftUI
import Charts

struct SpendingView: View {

    @Binding var selectedTab: Int
    @Environment(TransactionViewModel.self) var transactionVM
    @Environment(BudgetViewModel.self) var budgetVM

    init(selectedTab: Binding<Int> = .constant(0)) {
        _selectedTab = selectedTab
    }

    @State private var timeRange: TimeRange = .month
    @State private var selectedMonth: Date = Date()
    @State private var includeBills = true
    @State private var showingNetIncomeInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerControls
                monthScroller
                summaryCards
                breakdownSection
            }
            .padding()
        }
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Enums

extension SpendingView {
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

}

// MARK: - Header Controls

private extension SpendingView {
    var headerControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    /// Income (blue) and Total Spend (grey) per month for mini bar charts
    struct MonthSummary: Identifiable {
        let id = UUID()
        let date: Date
        let income: Double
        let spend: Double
    }

    var monthSummaries: [MonthSummary] {
        let cal = Calendar.current
        return (0..<6).compactMap { offset in
            guard let date = cal.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let txns = transactionVM.transactions.filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
            let income = txns.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
            let spend = txns.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
            return MonthSummary(date: date, income: income, spend: spend)
        }.reversed()
    }

    var monthScroller: some View {
        let calendar = Calendar.current
        let maxValue = max(monthSummaries.map(\.income).max() ?? 1, monthSummaries.map(\.spend).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(monthSummaries) { summary in
                        let isSelected = calendar.isDate(summary.date, equalTo: selectedMonth, toGranularity: .month)
                        monthCard(summary: summary, maxValue: maxValue, isSelected: isSelected) {
                            selectedMonth = summary.date
                        }
                    }
                    VStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 1, height: 40)
                        Text(String(calendar.component(.year, from: Date())))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 30)
                }
                .padding(.top, 4)
            }

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(incomeChartColor).frame(width: 8, height: 8)
                    Text("Income").font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(totalSpendChartColor).frame(width: 8, height: 8)
                    Text("Total Spend").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var incomeChartColor: Color { AppColors.skyBlue }
    private var totalSpendChartColor: Color { Color(.systemGray) }

    private func monthCard(summary: MonthSummary, maxValue: Double, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        let scale = maxValue > 0 ? maxValue : 1.0
        let barHeight: CGFloat = 44
        let incomeHeight = max(2, (summary.income / scale) * (barHeight - 4))
        let spendHeight = max(2, (summary.spend / scale) * (barHeight - 4))
        return Button(action: onTap) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(incomeChartColor)
                        .frame(width: 10, height: incomeHeight)
                        .frame(height: barHeight, alignment: .bottom)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(totalSpendChartColor)
                        .frame(width: 10, height: spendHeight)
                        .frame(height: barHeight, alignment: .bottom)
                }
                .frame(height: barHeight)

                Text(summary.date, format: .dateTime.month(.abbreviated))
                    .font(.subheadline.bold())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppColors.secondaryBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary

private extension SpendingView {
    var periodTransactions: [Transaction] {
        let cal = Calendar.current
        return transactionVM.transactions.filter { txn in
            switch timeRange {
            case .month:
                return cal.isDate(txn.date, equalTo: selectedMonth, toGranularity: .month)
            case .week:
                return cal.isDate(txn.date, equalTo: selectedMonth, toGranularity: .weekOfYear)
            case .quarter:
                guard let quarterRange = cal.dateInterval(of: .quarter, for: selectedMonth) else { return false }
                return quarterRange.contains(txn.date)
            case .year:
                return cal.isDate(txn.date, equalTo: selectedMonth, toGranularity: .year)
            }
        }
    }

    var incomeTotal: Double {
        periodTransactions
            .filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amount }
    }

    var expenseTotal: Double {
        periodTransactions
            .filter { $0.kind == .expense && (includeBills || $0.parsedCategory != .bills) }
            .reduce(0) { $0 + $1.amount }
    }

    var netIncome: Double { incomeTotal - expenseTotal }

    var summaryCards: some View {
        VStack(spacing: 12) {
            summaryRow(title: "Income", amount: incomeTotal, systemImage: "arrow.down.left.circle")

            Button {
                selectedTab = 7
            } label: {
                summaryRowContent(title: "Total Spent", amount: expenseTotal, systemImage: "arrow.up.right.circle")
            }
            .buttonStyle(.plain)

            Button {
                showingNetIncomeInfo = true
            } label: {
                HStack {
                    summaryRowContent(title: "Net Income", amount: netIncome, systemImage: "equal.circle")
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingNetIncomeInfo) {
            netIncomeInfoSheet
        }
    }

    private var netIncomeInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Net Income is what’s left after you subtract your total spending from your income for the period. A positive number means you saved money; a negative number means you spent more than you brought in.")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text("Example for your current period")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Income: \(currencyString(incomeTotal))")
                        Text("• Total Spent: \(currencyString(expenseTotal))")
                        Text("• Net Income = Income − Total Spent = \(currencyString(netIncome))")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("About Net Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingNetIncomeInfo = false }
                }
            }
        }
    }

    func summaryRow(title: String, amount: Double, systemImage: String) -> some View {
        summaryRowContent(title: title, amount: amount, systemImage: systemImage)
            .padding()
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func summaryRowContent(title: String, amount: Double, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
            Spacer()
            Text(currencyString(amount))
                .font(.subheadline.bold())
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Breakdown

private extension SpendingView {
    struct CategorySlice: Identifiable {
        let id = UUID()
        let label: String
        let color: Color
        let amount: Double
    }

    var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Breakdown")
                    .font(.headline)
                Spacer()
                Toggle("Include bills", isOn: $includeBills)
                    .toggleStyle(.switch)
                    .font(.caption)
            }

            if expenseTotal <= 0 {
                Text("Add some expenses to see a breakdown.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                categoryBreakdown
            }
        }
    }

    var categorySlices: [CategorySlice] {
        let grouped = Dictionary(grouping: periodTransactions.filter { $0.kind == .expense }) { $0.parsedCategory }
        return grouped.compactMap { category, txns in
            if !includeBills && category == .bills { return nil }
            let sum = txns.reduce(0) { $0 + $1.amount }
            guard sum > 0 else { return nil }
            return CategorySlice(label: category.rawValue, color: category.color, amount: sum)
        }
        .sorted { $0.amount > $1.amount }
    }

    private var selectedMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedMonth)
    }

    var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Chart(categorySlices) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount),
                        innerRadius: .ratio(0.80),
                        angularInset: 2
                    )
                    .foregroundStyle(slice.color)
                    .cornerRadius(6)
                }
                .frame(height: 260)
                .chartLegend(.hidden)

                VStack(spacing: 4) {
                    Text("Total spend in \(selectedMonthName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currencyString(expenseTotal))
                        .font(.title2.bold())
                }
                .multilineTextAlignment(.center)
            }
            .frame(height: 260)

            ForEach(categorySlices) { slice in
                HStack {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 10, height: 10)
                    Text(slice.label)
                        .font(.subheadline)
                    Spacer()
                    Text(percentageString(slice.amount, total: expenseTotal))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currencyString(slice.amount))
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

}

// MARK: - Formatting

private extension SpendingView {
    func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    func percentageString(_ value: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        let pct = value / total * 100
        return String(format: "%.0f%%", pct)
    }
}

