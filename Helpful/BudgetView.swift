import SwiftUI

struct BudgetView: View {

    @Environment(BudgetViewModel.self) var vm
    @State private var showingAdd = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if let msg = vm.rolloverMessage {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(msg)
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.teal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                List {
                    Section {
                        BudgetSummaryHeader(
                            totalBudget: vm.totalBudget,
                            totalSpent: vm.totalSpent
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)

                        BudgetOverviewRow(
                            totalBudget: vm.totalBudget,
                            totalSpent: vm.totalSpent
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                    }

                    if vm.budgets.isEmpty && !vm.isLoading {
                        ContentUnavailableView(
                            "No Budgets",
                            systemImage: "dollarsign.circle",
                            description: Text("Tap + to create your first budget.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(vm.budgets) { budget in
                        BudgetCard(budget: budget)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await vm.delete(budget) }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                    }

                    Section {
                        BudgetFAQSection()
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }

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
        .navigationTitle("Budgets")
        .sheet(isPresented: $showingAdd) {
            AddBudgetView()
        }
        .refreshable {
            await vm.load()
        }
        .background(AppColors.background.ignoresSafeArea())
    }
}

// MARK: - Summary Header & Cards

private struct BudgetSummaryHeader: View {
    let totalBudget: Double
    let totalSpent: Double

    private var hasBudget: Bool { totalBudget > 0 }
    private var overBudget: Bool { hasBudget && totalSpent > totalBudget }
    private var remaining: Double { max(totalBudget - totalSpent, 0) }
    private var difference: Double { abs(totalSpent - totalBudget) }
    private var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Spending", systemImage: "creditcard")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    if hasBudget {
                        Text("\(overBudget ? "" : "")\(currencyString(difference)) \(overBudget ? "over" : "left in") budget")
                            .font(.title3.weight(.semibold))
                        Text("\(currencyString(totalSpent)) spent of \(currencyString(totalBudget))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No budget set yet")
                            .font(.title3.weight(.semibold))
                        Text("Create a monthly budget to track your plan.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if hasBudget {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Left to spend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(currencyString(remaining))
                            .font(.headline.weight(.semibold))
                    }
                    .padding(8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColors.elevatedBackground.opacity(0.95))
                    )
                }
            }

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.9))
                    .frame(height: 10)
                GeometryReader { geo in
                    Capsule(style: .continuous)
                        .fill(overBudget ? Color.red : AppColors.skyBlue)
                        .frame(width: CGFloat(progress) * geo.size.width, height: 10)
                        .animation(.easeOut(duration: 0.25), value: progress)
                }
                .frame(height: 10)
            }

            HStack {
                Text("Spent: \(currencyString(totalSpent))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Budgeted: \(currencyString(totalBudget))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 12)
        )
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

private struct BudgetOverviewRow: View {
    let totalBudget: Double
    let totalSpent: Double

    private var remaining: Double { max(totalBudget - totalSpent, 0) }

    var body: some View {
        HStack(spacing: 12) {
            overviewCard(
                title: "Spent so far",
                subtitle: "This month",
                value: currencyString(totalSpent),
                systemImage: "arrow.up.right.circle"
            )

            overviewCard(
                title: "Left to spend",
                subtitle: totalBudget > 0 ? "Of your plan" : "Set a plan",
                value: currencyString(remaining),
                systemImage: "checkmark.seal"
            )
        }
    }

    private func overviewCard(
        title: String,
        subtitle: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Text(value)
                .font(.title3.weight(.bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
        )
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - FAQ Section

private struct BudgetFAQSection: View {
    @State private var expandedID: Int? = nil

    private struct Item: Identifiable {
        let id: Int
        let question: String
        let answer: String
    }

    private let items: [Item] = [
        .init(
            id: 1,
            question: "How is my budget calculated?",
            answer: "Your budget is the total amount you set for the month. As you log expenses, Helpful subtracts them from that total so you can see how much is left to spend."
        ),
        .init(
            id: 2,
            question: "What counts as \"spent\"?",
            answer: "Any transaction marked as an expense in the current month is counted toward your spending. Income transactions do not reduce your budget."
        ),
        .init(
            id: 3,
            question: "What happens if I go over budget?",
            answer: "If your spending goes over the amount you planned, Helpful will show that you’re over budget and highlight it so you know to slow down for the rest of the month."
        ),
        .init(
            id: 4,
            question: "Can I change my budget later?",
            answer: "Yes. You can add a new budget for the current month at any time if your plan changes."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked Questions")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedID == item.id },
                            set: { expandedID = $0 ? item.id : nil }
                        )
                    ) {
                        Text(item.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } label: {
                        Text(item.question)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.elevatedBackground.opacity(0.98))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
        )
    }
}

// MARK: - Budget Card

private struct BudgetCard: View {
    let budget: Budget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(budget.month)
                    .font(.headline)
                Spacer()
                Text(currencyString(budget.total))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.coral)
            }

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.9))
                    .frame(height: 10)
                GeometryReader { geo in
                    Capsule(style: .continuous)
                        .fill(budget.progress > 0.85 ? Color.red : AppColors.teal)
                        .frame(width: max(4, CGFloat(budget.progress) * geo.size.width), height: 10)
                        .animation(.easeOut(duration: 0.25), value: budget.progress)
                }
                .frame(height: 10)
            }

            HStack {
                Text("Spent: \(currencyString(budget.spent))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Left: \(currencyString(budget.remaining))")
                    .font(.caption)
                    .foregroundStyle(budget.remaining < 0 ? .red : .secondary)
            }
        }
        .cardStyle()
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
