import SwiftUI

struct GoalsView: View {

    @Environment(GoalViewModel.self) var vm
    @State private var showingAdd = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Section {
                    GoalsSummaryHeader(
                        totalSaved: vm.totalSaved,
                        totalTarget: vm.totalTarget,
                        completedCount: vm.goals.filter { $0.currentAmount >= $0.targetAmount }.count,
                        totalCount: vm.goals.count,
                        nextUpGoal: nextUpGoal
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)

                    GoalsOverviewRow(
                        totalSaved: vm.totalSaved,
                        closestGoal: closestGoal
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                }

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

                Section {
                    GoalsFAQSection()
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
        .background(AppColors.background.ignoresSafeArea())
    }

    private var closestGoal: Goal? {
        vm.goals
            .filter { $0.currentAmount < $0.targetAmount }
            .sorted { $0.remaining < $1.remaining }
            .first
    }

    private var nextUpGoal: Goal? {
        vm.goals
            .filter { $0.currentAmount < $0.targetAmount }
            .sorted {
                if $0.deadline == $1.deadline { return $0.remaining < $1.remaining }
                return $0.deadline < $1.deadline
            }
            .first
    }
}

// MARK: - Summary Header & Cards

private struct GoalsSummaryHeader: View {
    let totalSaved: Double
    let totalTarget: Double
    let completedCount: Int
    let totalCount: Int
    let nextUpGoal: Goal?

    private var progress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(totalSaved / totalTarget, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Goals", systemImage: "target")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(currencyString(totalSaved))
                        .font(.system(.title, design: .rounded).weight(.bold))

                    Text("Saved across \(totalCount) goal\(totalCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(completedCount)/\(max(totalCount, 1))")
                        .font(.headline.weight(.semibold))
                }
                .padding(8)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.elevatedBackground.opacity(0.95))
                )
            }

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.9))
                    .frame(height: 10)
                GeometryReader { geo in
                    Capsule(style: .continuous)
                        .fill(AppGradients.teal)
                        .frame(width: CGFloat(progress) * geo.size.width, height: 10)
                        .animation(.easeOut(duration: 0.25), value: progress)
                }
                .frame(height: 10)
            }

            if let next = nextUpGoal {
                HStack(spacing: 10) {
                    Text(next.emoji)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next up: \(next.title)")
                            .font(.subheadline.weight(.semibold))
                        Text("\(currencyString(next.remaining)) left · due \(next.deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppColors.elevatedBackground.opacity(0.95))
                )
            } else {
                Text("Add your next goal to stay motivated.")
                    .font(.subheadline)
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

private struct GoalsOverviewRow: View {
    let totalSaved: Double
    let closestGoal: Goal?

    var body: some View {
        HStack(spacing: 12) {
            overviewCard(
                title: "Total saved",
                subtitle: "All goals",
                value: currencyString(totalSaved),
                systemImage: "banknote"
            )

            overviewCard(
                title: "Closest goal",
                subtitle: closestGoal?.title ?? "—",
                value: closestGoal.map { currencyString($0.remaining) } ?? "—",
                systemImage: "bolt.fill"
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
                    .foregroundStyle(AppColors.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal
    let vm: GoalViewModel

    @State private var addAmountString = ""
    @State private var showingAddFunds = false

    var body: some View {
        HStack(spacing: 14) {
            Text(goal.emoji)
                .font(.system(size: 32))
                .frame(width: 52, height: 52)
                .background(AppColors.elevatedBackground.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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

                HStack(spacing: 8) {
                    pill(text: "\(currencyString(goal.remaining)) left", systemImage: "flag.checkered")
                    pill(text: dueText, systemImage: "calendar")
                    Spacer(minLength: 0)
                }

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AppColors.elevatedBackground.opacity(0.9))
                        .frame(height: 8)
                    GeometryReader { geo in
                        Capsule(style: .continuous)
                            .fill(progressColor)
                            .frame(width: max(4, CGFloat(goal.progress) * geo.size.width), height: 8)
                            .animation(.easeOut(duration: 0.25), value: goal.progress)
                    }
                    .frame(height: 8)
                }

                HStack {
                    Text(currencyString(goal.currentAmount))
                        .font(.caption2.bold())
                        .foregroundStyle(progressColor)
                    Spacer()
                    Text("of \(currencyString(goal.targetAmount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(trackText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(trackColor)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
        )
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

    private var daysRemaining: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: goal.deadline)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private var dueText: String {
        if goal.progress >= 1.0 { return "Completed" }
        if daysRemaining < 0 { return "Past due" }
        if daysRemaining == 0 { return "Due today" }
        if daysRemaining == 1 { return "Due in 1 day" }
        return "Due in \(daysRemaining)d"
    }

    private var expectedProgress: Double {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        let endOfDeadline = cal.startOfDay(for: goal.deadline)
        guard endOfDeadline > startOfToday else { return 1.0 }

        let totalDays = cal.dateComponents([.day], from: startOfToday, to: endOfDeadline).day ?? 0
        guard totalDays > 0 else { return 0 }

        // Expectation: you should be roughly proportional to time elapsed in the remaining window.
        // Since we don't store goal start date, we treat "now -> deadline" as the active window
        // and only mark "Behind" when progress is very low near deadline.
        let urgency = min(1.0, max(0.0, 1.0 - Double(totalDays) / 30.0)) // ramps up in last ~30 days
        return min(0.9, urgency) // cap expectation; keep it gentle
    }

    private var trackText: String {
        if goal.progress >= 1.0 { return "On track" }
        if daysRemaining < 0 { return "Behind" }
        if goal.progress >= expectedProgress { return "On track" }
        return "Behind"
    }

    private var trackColor: Color {
        trackText == "Behind" ? .orange : AppColors.teal
    }

    private func pill(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.95))
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

private struct GoalsFAQSection: View {
    @State private var expandedID: Int? = nil

    private struct Item: Identifiable {
        let id: Int
        let question: String
        let answer: String
    }

    private let items: [Item] = [
        .init(
            id: 1,
            question: "How does goal progress work?",
            answer: "Each goal has a target amount and a current saved amount. When you add funds, Helpful updates the current amount and shows your progress toward the target."
        ),
        .init(
            id: 2,
            question: "What does “On track” mean?",
            answer: "It’s a gentle indicator based on how close your deadline is and how much you’ve saved so far. If you’re near the deadline with very low progress, it may show “Behind.”"
        ),
        .init(
            id: 3,
            question: "Can I change a goal later?",
            answer: "Yes—you can keep adding funds over time, and you can also create a new goal if your priorities change."
        ),
        .init(
            id: 4,
            question: "What’s a good first goal?",
            answer: "A small emergency fund is a great start. Try setting a realistic target and a deadline that feels achievable, then add a little each week."
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
