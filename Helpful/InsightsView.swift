import SwiftUI
import Charts

struct InsightsView: View {

    @Environment(TransactionViewModel.self) var txnVM
    @Environment(BudgetViewModel.self) var budgetVM

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if txnVM.transactions.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Add some transactions to see your spending insights.")
                    )
                    .padding(.top, 60)
                } else {
                    topCategoryCard
                    categoryPieChart
                    budgetVsActual
                    weeklyBarChart
                    monthlyTrendLine
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Top Category

    private var topCategoryCard: some View {
        let grouped = Dictionary(grouping: currentMonthTransactions) { $0.parsedCategory }
        let top = grouped.max(by: { $0.value.reduce(0) { $0 + $1.amount } < $1.value.reduce(0) { $0 + $1.amount } })
        let topAmount = top?.value.reduce(0) { $0 + $1.amount } ?? 0
        let totalAmount = currentMonthTransactions.reduce(0) { $0 + $1.amount }
        let pct = totalAmount > 0 ? (topAmount / totalAmount * 100) : 0

        return GradientCard(gradient: AppGradients.primary) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Top Category", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.85))
                    Text(top?.key.rawValue ?? "—")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("\(currencyString(topAmount)) · \(String(format: "%.0f", pct))%")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: top?.key.icon ?? "questionmark.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Pie Chart

    private var categoryPieChart: some View {
        let data = categoryData
        return VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)

            Chart(data, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(4)
            }
            .frame(height: 220)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(data, id: \.category) { item in
                    HStack(spacing: 6) {
                        Circle().fill(item.category.color).frame(width: 10, height: 10)
                        Text(item.category.rawValue)
                            .font(.caption)
                        Spacer()
                        Text(currencyString(item.amount))
                            .font(.caption.bold())
                    }
                }
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Budget vs Actual

    @ViewBuilder
    private var budgetVsActual: some View {
        let monthName = currentMonthName
        if let budget = budgetVM.budgets.first(where: { $0.month == monthName }) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Budget vs Actual")
                    .font(.headline)

                Chart {
                    BarMark(x: .value("Amount", budget.total), y: .value("Type", "Budget"))
                        .foregroundStyle(AppColors.teal.opacity(0.6))
                        .cornerRadius(6)
                    BarMark(x: .value("Amount", budget.spent), y: .value("Type", "Spent"))
                        .foregroundStyle(budget.spent > budget.total ? Color.red : AppColors.coral)
                        .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(shortCurrency(v))
                            }
                        }
                    }
                }
                .frame(height: 100)

                HStack {
                    Label("Budget: \(currencyString(budget.total))", systemImage: "target")
                        .font(.caption)
                    Spacer()
                    Label("Spent: \(currencyString(budget.spent))", systemImage: "cart.fill")
                        .font(.caption)
                        .foregroundStyle(budget.spent > budget.total ? .red : .secondary)
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Weekly Bar Chart

    private var weeklyBarChart: some View {
        let data = weeklyData
        return VStack(alignment: .leading, spacing: 12) {
            Text("This Month — Weekly")
                .font(.headline)

            Chart(data, id: \.week) { item in
                BarMark(
                    x: .value("Week", item.week),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(AppGradients.primary)
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(shortCurrency(v))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Monthly Trend

    private var monthlyTrendLine: some View {
        let data = monthlyData
        return VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend")
                .font(.headline)

            Chart(data, id: \.month) { item in
                LineMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(AppColors.coral)
                .interpolationMethod(.catmullRom)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                .symbolSize(40)

                AreaMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.coral.opacity(0.3), AppColors.coral.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(shortCurrency(v))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Data Helpers

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var currentMonthTransactions: [Transaction] {
        let cal = Calendar.current
        return txnVM.transactions.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private struct CategoryAmount {
        let category: TransactionCategory
        let amount: Double
    }

    private var categoryData: [CategoryAmount] {
        let grouped = Dictionary(grouping: currentMonthTransactions) { $0.parsedCategory }
        return grouped.map { CategoryAmount(category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }

    private struct WeekAmount {
        let week: String
        let amount: Double
    }

    private var weeklyData: [WeekAmount] {
        let cal = Calendar.current
        let txns = currentMonthTransactions
        var weeks: [Int: Double] = [:]
        for txn in txns {
            let weekOfMonth = cal.component(.weekOfMonth, from: txn.date)
            weeks[weekOfMonth, default: 0] += txn.amount
        }
        return weeks.sorted { $0.key < $1.key }
            .map { WeekAmount(week: "Week \($0.key)", amount: $0.value) }
    }

    private struct MonthAmount {
        let month: String
        let amount: Double
    }

    private var monthlyData: [MonthAmount] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var result: [MonthAmount] = []
        for offset in stride(from: -5, through: 0, by: 1) {
            guard let date = cal.date(byAdding: .month, value: offset, to: Date()) else { continue }
            let txns = txnVM.transactions.filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
            let total = txns.reduce(0) { $0 + $1.amount }
            result.append(MonthAmount(month: formatter.string(from: date), amount: total))
        }
        return result
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func shortCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return "$\(String(format: "%.0f", value / 1000))k"
        }
        return "$\(String(format: "%.0f", value))"
    }
}
