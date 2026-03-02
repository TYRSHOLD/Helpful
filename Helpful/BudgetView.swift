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

            ProgressView(value: budget.progress)
                .tint(budget.progress > 0.85 ? .red : AppColors.teal)
                .scaleEffect(y: 2)

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
