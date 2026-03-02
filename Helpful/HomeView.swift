import SwiftUI

struct HomeView: View {

    @Binding var selectedTab: Int

    @Environment(AuthViewModel.self) var auth
    @Environment(BudgetViewModel.self) var budgetVM
    @Environment(TransactionViewModel.self) var transactionVM
    @Environment(GoalViewModel.self) var goalVM
    @Environment(OpportunityViewModel.self) var opportunityVM
    @Environment(AchievementViewModel.self) var achievementVM

    @State private var showingProfile = false
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        List {
            Section {
                greetingHeader
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                summaryCards
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                quickActions
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section {
                recentTransactionsHeader
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if transactionVM.transactions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                        ForEach(transactionVM.recentTransactions) { txn in
                        TransactionRow(transaction: txn)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTransaction = txn }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        if txn.kind == .expense {
                                            await budgetVM.subtractSpending(amount: txn.amount)
                                        }
                                        await transactionVM.delete(txn)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            async let b: () = budgetVM.load()
            async let t: () = transactionVM.load()
            async let g: () = goalVM.load()
            _ = await (b, t, g)
        }
        .task(id: transactionVM.transactions.count + goalVM.goals.count) {
            let completedGoals = goalVM.goals.filter { $0.currentAmount >= $0.targetAmount }.count
            let underBudget = budgetVM.budgets.filter { $0.spent <= $0.total && $0.spent > 0 }.count
            await achievementVM.checkBadges(
                transactionCount: transactionVM.transactions.count,
                goalsSaved: goalVM.totalSaved,
                completedGoals: completedGoals,
                budgetUnderCount: underBudget,
                documentCount: 0,
                savedOpportunityCount: opportunityVM.savedOpportunities.count
            )
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { auth.signOut() } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingProfile = true } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.coral)
                }
            }
        }
        .sheet(isPresented: $showingProfile) { ProfileView() }
        .sheet(isPresented: $showingAddTransaction) { AddTransactionView() }
        .sheet(item: $selectedTransaction) { txn in
            TransactionDetailView(transaction: txn)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(greeting)
                    .font(.title2.bold())
                if achievementVM.streakDays > 0 {
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(achievementVM.streakDays)")
                            .font(.subheadline.bold())
                    }
                }
            }
            Text("Here's your financial overview")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var greeting: String {
        let name = auth.userName.isEmpty ? "there" : auth.userName.components(separatedBy: " ").first ?? auth.userName
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 0..<12: timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default: timeOfDay = "Good evening"
        }
        return "\(timeOfDay), \(name)!"
    }

    // MARK: - Summary Cards (tappable)

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { selectedTab = 1 } label: {
                    GradientCard(gradient: AppGradients.primary) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Budget", systemImage: "dollarsign.circle")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                            Text(currencyString(budgetVM.totalBudget))
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button { selectedTab = 2 } label: {
                    GradientCard(gradient: AppGradients.teal) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Spent", systemImage: "cart.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                            Text(currencyString(transactionVM.totalSpent))
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button { selectedTab = 3 } label: {
                    GradientCard(gradient: AppGradients.purple) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Saved", systemImage: "star.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                            Text(currencyString(goalVM.totalSaved))
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button { selectedTab = 3 } label: {
                    GradientCard(gradient: AppGradients.blue) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Goals", systemImage: "target")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                            Text("\(goalVM.goals.count)")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Button { selectedTab = 6 } label: {
                GradientCard(gradient: AppGradients.discover) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Opportunities", systemImage: "sparkles")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                            Text("\(opportunityVM.savedCount) saved")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    quickActionButton(title: "Add Transaction", icon: "plus.circle.fill", color: AppColors.coral) {
                        showingAddTransaction = true
                    }
                    quickActionButton(title: "Budgets", icon: "dollarsign.circle.fill", color: AppColors.teal) {
                        selectedTab = 1
                    }
                    quickActionButton(title: "Documents", icon: "doc.text.fill", color: AppColors.purple) {
                        selectedTab = 4
                    }
                    quickActionButton(title: "GPA Calc", icon: "function", color: AppColors.skyBlue) {
                        selectedTab = 5
                    }
                    quickActionButton(title: "Discover", icon: "sparkles", color: AppColors.purple) {
                        selectedTab = 6
                    }
                }
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsHeader: some View {
        HStack {
            Text("Recent Transactions")
                .font(.headline)
            Spacer()
            if !transactionVM.transactions.isEmpty {
                Button("See All") { selectedTab = 2 }
                    .font(.subheadline)
                    .foregroundStyle(AppColors.coral)
            }
        }
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Transaction Row (shared)

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.parsedCategory.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(transaction.parsedCategory.color)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.parsedCategory.rawValue)
                    .font(.subheadline.bold())
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyString(transaction.amount))
                    .font(.subheadline.bold())
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
