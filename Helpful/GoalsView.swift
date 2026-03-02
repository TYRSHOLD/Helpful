import SwiftUI

struct GoalsView: View {

    @Environment(GoalViewModel.self) var vm
    @State private var showingAdd = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                if vm.goals.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "No Goals Yet",
                        systemImage: "target",
                        description: Text("Tap + to set your first savings goal.")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(vm.goals) { goal in
                    GoalCard(goal: goal, vm: vm)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await vm.delete(goal) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                }
            }
            .listStyle(.plain)

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
        .navigationTitle("Goals")
        .sheet(isPresented: $showingAdd) {
            AddGoalView()
        }
        .refreshable {
            await vm.load()
        }
    }
}

// MARK: - Compact Goal Card

struct GoalCard: View {
    let goal: Goal
    let vm: GoalViewModel

    @State private var addAmountString = ""
    @State private var showingAddFunds = false

    var body: some View {
        HStack(spacing: 14) {
            Text(goal.emoji)
                .font(.system(size: 36))
                .frame(width: 52, height: 52)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(goal.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Menu {
                        Button { showingAddFunds = true } label: {
                            Label("Add Funds", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }

                ProgressView(value: goal.progress)
                    .tint(progressColor)
                    .scaleEffect(y: 1.5)

                HStack {
                    Text(currencyString(goal.currentAmount))
                        .font(.caption2.bold())
                        .foregroundStyle(progressColor)
                    Spacer()
                    Text("of \(currencyString(goal.targetAmount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(goal.deadline, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .alert("Add Funds", isPresented: $showingAddFunds) {
            TextField("Amount", text: $addAmountString)
                .keyboardType(.decimalPad)
            Button("Add") {
                if let amount = Double(addAmountString) {
                    Task { await vm.updateProgress(goal: goal, newAmount: goal.currentAmount + amount) }
                }
                addAmountString = ""
            }
            Button("Cancel", role: .cancel) { addAmountString = "" }
        } message: {
            Text("How much did you save toward \"\(goal.title)\"?")
        }
    }

    private var progressColor: Color {
        if goal.progress >= 1.0 { return AppColors.green }
        if goal.progress >= 0.5 { return AppColors.teal }
        return AppColors.coral
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
