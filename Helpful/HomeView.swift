import SwiftUI

struct HomeView: View {

    @Binding var selectedTab: Int
    @Binding var pendingMoreDestination: MoreDestination?

    @Environment(AuthViewModel.self) var auth
    @Environment(BudgetViewModel.self) var budgetVM
    @Environment(TransactionViewModel.self) var transactionVM
    @Environment(GoalViewModel.self) var goalVM
    @Environment(OpportunityViewModel.self) var opportunityVM
    @Environment(AchievementViewModel.self) var achievementVM
    @Environment(AIInsightsViewModel.self) var aiInsightsVM

    @State private var showingProfile = false
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                greetingHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                summaryCards
                    .padding(.horizontal, 16)

                quickActions
                    .padding(.horizontal, 16)

                if !transactionVM.transactions.isEmpty {
                    aiInsightsSection
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 12) {
                    recentTransactionsHeader
                    recentTransactionsContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .padding(.top, 4)
        }
        .background(AppColors.background.ignoresSafeArea())
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
            await aiInsightsVM.refreshIfNeeded(
                transactions: transactionVM.transactions,
                budgets: budgetVM.budgets,
                goals: goalVM.goals
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(greeting)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Spacer()
                streakPill
            }
            Text("Here's your financial overview")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(achievementVM.streakDays)d")
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.9))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
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
                GradientCard(gradient: AppGradients.green) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Earned", systemImage: "arrow.down.left.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.85))
                        Text(currencyString(transactionVM.totalIncome))
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

            Button { selectedTab = 4 } label: {
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
            .gridCellColumns(2)
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
                    quickActionButton(title: "Add Goal", icon: "target", color: AppColors.purple) {
                        selectedTab = 3
                    }
                    quickActionButton(title: "Insights", icon: "chart.pie.fill", color: AppColors.skyBlue) {
                        selectedTab = 2
                    }
                    quickActionButton(title: "Docs", icon: "doc.text.fill", color: AppColors.purple) {
                        pendingMoreDestination = .documents
                        selectedTab = 4
                    }
                    quickActionButton(title: "Ask Helpful AI", icon: "bubble.left.and.bubble.right.fill", color: AppColors.coral) {
                        pendingMoreDestination = .helpfulAI
                        selectedTab = 4
                    }
                }
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.9))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(color.opacity(0.18), lineWidth: 1)
                    )
            )
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

    private var recentTransactionsContent: some View {
        Group {
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
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.elevatedBackground.opacity(0.9))
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(transactionVM.recentTransactions) { txn in
                        TransactionRow(transaction: txn)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTransaction = txn }
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
    }

    // MARK: - AI Insights

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                if aiInsightsVM.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Spacer()
                Button("Refresh") {
                    Task {
                        await aiInsightsVM.generate(
                            transactions: transactionVM.transactions,
                            budgets: budgetVM.budgets,
                            goals: goalVM.goals
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(AppColors.coral)
            }

            if let error = aiInsightsVM.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if aiInsightsVM.insights.isEmpty {
                Text("Once you have some activity, Helpful AI will surface personalized tips here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(aiInsightsVM.insights.prefix(2)) { insight in
                    aiInsightCard(insight)
                }
            }
        }
    }

    private func aiInsightCard(_ insight: AIInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(color(for: insight.category))
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: insight.icon)
                        .foregroundStyle(color(for: insight.category))
                    Text(insight.title)
                        .font(.subheadline.bold())
                    Spacer()
                }
                Text(insight.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func color(for category: InsightCategory) -> Color {
        switch category {
        case .warning: return .orange
        case .tip: return AppColors.teal
        case .celebration: return AppColors.green
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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(transaction.parsedCategory.color.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: transaction.parsedCategory.icon)
                    .font(.title3)
                    .foregroundStyle(transaction.parsedCategory.color)
            }

            VStack(alignment: .leading, spacing: 4) {
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(currencyString(transaction.amount))
                    .font(.subheadline.bold())
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
