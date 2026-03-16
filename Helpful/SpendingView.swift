import SwiftUI
import Charts

struct SpendingView: View {

    @Binding var selectedTab: Int
    @Binding var pendingMoreDestination: MoreDestination?
    @Environment(TransactionViewModel.self) var transactionVM
    @Environment(BudgetViewModel.self) var budgetVM
    @Environment(GoalViewModel.self) var goalVM
    @Environment(AuthViewModel.self) private var auth
    @State private var plaidError: String?
    @State private var plaidSuccess = false

    init(
        selectedTab: Binding<Int> = .constant(0),
        pendingMoreDestination: Binding<MoreDestination?> = .constant(nil)
    ) {
        _selectedTab = selectedTab
        _pendingMoreDestination = pendingMoreDestination
    }

    @State private var timeRange: TimeRange = .month
    @State private var selectedMonth: Date = Date()
    @State private var includeBills = true
    @State private var showingNetIncomeInfo = false
    @State private var selectedForecastPoint: ForecastPoint?
    @State private var isInteractingWithForecast = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerControls
                monthScroller
                summaryCards
                forecastSection
                breakdownSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.large)
        .alert("Plaid", isPresented: Binding(
            get: { plaidError != nil },
            set: { if !$0 { plaidError = nil } }
        )) {
            Button("OK", role: .cancel) { plaidError = nil }
        } message: {
            if let msg = plaidError { Text(msg) }
        }
        .alert("Bank connected", isPresented: $plaidSuccess) {
            Button("OK") { plaidSuccess = false }
        } message: {
            Text("Your account is linked. Transactions will sync automatically.")
        }
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
            Text("Overview")
                .font(.headline)
                .foregroundStyle(.secondary)

            Picker("Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.95))
            )
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

        return VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(monthSummaries.enumerated()), id: \.element.id) { index, summary in
                        let isSelected = calendar.isDate(summary.date, equalTo: selectedMonth, toGranularity: .month)
                        monthCard(summary: summary, maxValue: maxValue, isSelected: isSelected) {
                            selectedMonth = summary.date
                        }

                        if index < monthSummaries.count - 1 {
                            let currentYear = calendar.component(.year, from: summary.date)
                            let nextYear = calendar.component(.year, from: monthSummaries[index + 1].date)
                            if currentYear != nextYear {
                                VStack(spacing: 6) {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.4))
                                        .frame(width: 1, height: 40)
                                    Text(String(nextYear))
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .rotationEffect(.degrees(-90))
                                }
                                .frame(width: 30)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }

            HStack(spacing: 20) {
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
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppColors.elevatedBackground.opacity(0.95) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.coral.opacity(0.35) : Color.clear, lineWidth: 2)
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

    var forecastResult: ForecastResult? {
        guard timeRange == .month else { return nil }
        let startingBalance = goalVM.totalSaved
        let monthlyNet = netIncome
        let months = 6
        return ForecastEngine.makeSavingsForecast(
            startingBalance: startingBalance,
            monthlyNet: monthlyNet,
            months: months
        )
    }

    var summaryCards: some View {
        VStack(spacing: 12) {
            connectBankRow
            summaryRow(title: "Income", amount: incomeTotal, systemImage: "arrow.down.left.circle", accentColor: AppColors.green)

            Button {
                pendingMoreDestination = .transactions
                selectedTab = 4
            } label: {
                summaryRow(title: "Total Spent", amount: expenseTotal, systemImage: "arrow.up.right.circle", accentColor: AppColors.coral)
            }
            .buttonStyle(.plain)

            Button {
                showingNetIncomeInfo = true
            } label: {
                summaryRow(title: "Net Income", amount: netIncome, systemImage: "equal.circle", accentColor: netIncome >= 0 ? AppColors.teal : .red)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingNetIncomeInfo) {
            netIncomeInfoSheet
        }
    }

    private var connectBankRow: some View {
        Button {
            guard let uid = auth.currentUserId else { return }
            PlaidService.shared.presentLink(
                userId: uid,
                onSuccess: { _ in
                    plaidSuccess = true
                    Task { await transactionVM.load() }
                },
                onExit: { },
                onFailure: { plaidError = $0 }
            )
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.teal.opacity(0.16))
                    Image(systemName: "link.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.teal)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect bank")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Link your account to import transactions")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.98))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Simple Savings Forecast")
                .font(.headline)

            if timeRange != .month {
                Text("Switch to the Month range to see an interactive 6‑month savings forecast.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let forecast = forecastResult, !forecast.points.isEmpty {
                let lastValue = forecast.points.last?.value ?? goalVM.totalSaved

                ZStack {
                    Chart {
                        ForEach(forecast.points, id: \.id) { point in
                            LineMark(
                                x: .value("Month", point.date, unit: .month),
                                y: .value("Estimated Savings", point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColors.teal, AppColors.skyBlue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                            if let selected = selectedForecastPoint,
                               selected.id == point.id {
                                PointMark(
                                    x: .value("Month", point.date, unit: .month),
                                    y: .value("Estimated Savings", point.value)
                                )
                                .symbolSize(80)
                                .foregroundStyle(AppColors.coral)
                                .annotation(position: .top) {
                                    forecastCallout(for: point)
                                }
                            }
                        }

                        if let selected = selectedForecastPoint {
                            RuleMark(
                                x: .value("Selected Month", selected.date, unit: .month)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
                    .chartYAxis(.hidden)
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            guard let plotFrame = proxy.plotContainerFrame else { return }
                                            isInteractingWithForecast = true
                                            let locationX = value.location.x - geo[plotFrame].origin.x
                                            if let date: Date = proxy.value(atX: locationX) {
                                                if let nearest = nearestForecastPoint(to: date, in: forecast.points) {
                                                    selectedForecastPoint = nearest
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            isInteractingWithForecast = false
                                        }
                                )
                        }
                    }
                    .frame(height: 200)
                }

                Text(summaryText(for: lastValue))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Once you have some net income this month, I'll show how your total savings could change over the next few months.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
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

    func summaryRow(title: String, amount: Double, systemImage: String, accentColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.16))
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(currencyString(amount))
                    .font(.headline.weight(.semibold))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
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

    func nearestForecastPoint(to date: Date, in points: [ForecastPoint]) -> ForecastPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: { lhs, rhs in
            abs(lhs.date.timeIntervalSince1970 - date.timeIntervalSince1970) <
            abs(rhs.date.timeIntervalSince1970 - date.timeIntervalSince1970)
        })
    }

    func summaryText(for projectedSavings: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let current = formatter.string(from: NSNumber(value: goalVM.totalSaved)) ?? "$0.00"
        let projected = formatter.string(from: NSNumber(value: projectedSavings)) ?? "$0.00"

        if netIncome > 0 {
            return "If your net income stays about the same, your total saved across goals could grow from \(current) to around \(projected) over the next 6 months."
        } else if netIncome < 0 {
            return "Right now you're spending more than you earn. If that continues, your total saved across goals could trend down toward \(projected) over the next 6 months."
        } else {
            return "With net income around zero this month, your total saved across goals is likely to stay close to \(current) over the next 6 months."
        }
    }

    func forecastCallout(for point: ForecastPoint) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let valueString = formatter.string(from: NSNumber(value: point.value)) ?? "$0.00"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        return VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: point.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(valueString)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
    }
}

