import SwiftUI

struct AIChatView: View {

    @Environment(AuthViewModel.self) var auth
    @Environment(TransactionViewModel.self) var txnVM
    @Environment(BudgetViewModel.self) var budgetVM
    @Environment(GoalViewModel.self) var goalVM

    @State private var aiVM = AIViewModel()
    @State private var inputText: String = ""
    @State private var isAnimatingAssistant = false
    @State private var selectedAction: AIViewModel.ChatAction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(aiVM.messages) { message in
                                chatBubble(for: message)
                                    .id(message.id)
                            }

                            if aiVM.isSending {
                                HStack(alignment: .center, spacing: 6) {
                                    TypingIndicatorView()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .onChange(of: aiVM.messages.count) { _, _ in
                        if let lastId = aiVM.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                if let error = aiVM.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }

                inputBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(AppColors.secondaryBackground)
            }
            .navigationTitle("Ask Helpful AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                if aiVM.messages.isEmpty {
                    await sendInitialGreeting()
                }
            }
            .onChange(of: aiVM.messages.count) { _, _ in
                animateLastAssistantMessageIfNeeded()
            }
            .onChange(of: aiVM.pendingActions.count) { _, _ in
                if selectedAction == nil, let first = aiVM.pendingActions.first {
                    selectedAction = first
                }
            }
            .sheet(item: $selectedAction, onDismiss: {
                consumeSelectedAction()
            }) { action in
                ActionConfirmationView(
                    action: action,
                    currencyString: currencyString,
                    createGoal: { title, amount, monthsFromNow in
                        Task {
                            let months = monthsFromNow ?? 6
                            let deadline = Calendar.current.date(
                                byAdding: .month,
                                value: months,
                                to: Date()
                            ) ?? Date()
                            await goalVM.add(
                                title: title,
                                emoji: "🎯",
                                targetAmount: amount,
                                deadline: deadline
                            )
                            selectedAction = nil
                        }
                    },
                    createBudget: { month, total in
                        Task {
                            let monthName = month ?? {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMMM"
                                return formatter.string(from: Date())
                            }()
                            await budgetVM.add(month: monthName, total: total)
                            selectedAction = nil
                        }
                    },
                    cancel: {
                        selectedAction = nil
                    }
                )
            }
        }
    }

    private func chatBubble(for message: AIViewModel.ChatMessage) -> some View {
        let isUser = message.role == .user

        return HStack {
            if isUser { Spacer() }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.displayedContent ?? message.content)
                    .font(.subheadline)
                    .foregroundStyle(isUser ? Color.white : AppColors.textPrimary)
                    .padding(10)
                    .background(
                        isUser
                        ? AppGradients.primary
                        : LinearGradient(
                            colors: [AppColors.secondaryBackground, AppColors.secondaryBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .frame(maxWidth: 320, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer() }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask a question about your money…", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                Task { await sendCurrentMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.coral)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiVM.isSending)
        }
    }

    private func buildContext() -> AIService.FinancialContext {
        let name = auth.userName.isEmpty ? "there" : auth.userName

        let school = auth.currentUser?.profile.school ?? ""
        let major = auth.currentUser?.profile.major ?? ""

        let cal = Calendar.current
        let currentMonthTxns = txnVM.transactions.filter {
            cal.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }

        let totalSpent = currentMonthTxns
            .filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }

        let totalIncome = currentMonthTxns
            .filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amount }

        let netIncome = totalIncome - totalSpent

        let groupedByCategory = Dictionary(grouping: currentMonthTxns.filter { $0.kind == .expense }) {
            $0.parsedCategory
        }
        let topCategories = groupedByCategory
            .map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
            .prefix(3)

        let topCategorySummary: String
        if topCategories.isEmpty {
            topCategorySummary = "No clear spending categories yet."
        } else {
            let parts = topCategories.map { "\($0.category.rawValue): \(currencyString($0.amount))" }
            topCategorySummary = parts.joined(separator: ", ")
        }

        let activeGoals = goalVM.goals
        let goalsSummary: String
        if activeGoals.isEmpty {
            goalsSummary = "No savings goals set."
        } else {
            let parts = activeGoals.prefix(3).map {
                "\"\($0.title)\" \($0.currentAmount)/\($0.targetAmount)"
            }
            goalsSummary = parts.joined(separator: "; ")
        }

        let budgetMonthName: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return formatter.string(from: Date())
        }()

        let currentBudget = budgetVM.budgets.first { $0.month == budgetMonthName }

        let currentBudgetTotal = currentBudget?.total ?? 0
        let currentBudgetSpent = currentBudget?.spent ?? totalSpent

        let netSummary = "Income this month: \(currencyString(totalIncome)), expenses: \(currencyString(totalSpent)), net: \(currencyString(netIncome))."

        return AIService.FinancialContext(
            userName: name,
            school: school,
            major: major,
            currentBudgetTotal: currentBudgetTotal,
            currentBudgetSpent: currentBudgetSpent,
            topCategorySummary: topCategorySummary,
            goalsSummary: goalsSummary,
            netIncomeSummary: netSummary
        )
    }

    private func sendCurrentMessage() async {
        let text = inputText
        inputText = ""
        let context = buildContext()
        await aiVM.send(text: text, context: context)
    }

    private func sendInitialGreeting() async {
        let intro = """
        I'm Helpful AI. I can explain your spending, help you budget, and give tips based on your actual numbers.
        You can ask things like:
        • \"Why am I spending so much this month?\"
        • \"How much can I spend on food and still stay on budget?\"
        • \"What should I focus on saving for next?\"
        """
        aiVM.messages.append(
            .init(role: .assistant, content: intro, displayedContent: intro, timestamp: Date())
        )
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    @Environment(\.dismiss) private var dismiss
}

// MARK: - Action Confirmation

private struct ActionConfirmationView: View {
    let action: AIViewModel.ChatAction
    let currencyString: (Double) -> String
    let createGoal: (_ title: String, _ amount: Double, _ monthsFromNow: Int?) -> Void
    let createBudget: (_ month: String?, _ total: Double) -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if action.kind == .createGoal {
                Text("Create savings goal?")
                    .font(.headline)
                Text(action.title)
                    .font(.title3.bold())
                Text("Target: \(currencyString(action.amount))")
                    .font(.subheadline)
                if let months = action.monthsFromNow {
                    Text("Deadline in about \(months) month\(months == 1 ? "" : "s").")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button("Create Goal") {
                    createGoal(action.title, action.amount, action.monthsFromNow)
                }
                .buttonStyle(.borderedProminent)
                Button("Not now", action: cancel)
                    .buttonStyle(.borderless)
            } else {
                Text("Create monthly budget?")
                    .font(.headline)
                if let month = action.month {
                    Text("Month: \(month)")
                        .font(.title3.bold())
                }
                Text("Total: \(currencyString(action.amount))")
                    .font(.subheadline)
                Button("Create Budget") {
                    createBudget(action.month, action.amount)
                }
                .buttonStyle(.borderedProminent)
                Button("Not now", action: cancel)
                    .buttonStyle(.borderless)
            }
        }
        .padding()
        .presentationDetents([.fraction(0.35), .medium])
    }
}

// MARK: - Typing Indicator

private struct TypingIndicatorView: View {
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppColors.coral.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .scaleEffect(scale(for: index))
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.12),
                        value: phase
                    )
            }
        }
        .padding(8)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            phase = 1
        }
    }

    private func scale(for index: Int) -> CGFloat {
        let base: CGFloat = 0.7
        let maxScale: CGFloat = 1.1
        let offset = Double(index) * 0.2
        let value = sin((phase + offset) * .pi)
        let normalized = (value + 1) / 2
        return base + (maxScale - base) * CGFloat(normalized)
    }
}

// MARK: - Assistant Message Animation

private extension AIChatView {
    func animateLastAssistantMessageIfNeeded() {
        guard !isAnimatingAssistant,
              let last = aiVM.messages.last,
              last.role == .assistant,
              let animatingID = aiVM.animatingMessageID,
              last.id == animatingID
        else { return }

        isAnimatingAssistant = true

        Task { @MainActor in
            let fullText = last.content
            let totalChars = fullText.count
            guard totalChars > 0 else {
                completeAnimation(for: last.id, text: fullText)
                return
            }

            let minDuration: Double = 0.5
            let maxDuration: Double = 1.5
            let clampedLength = min(Double(totalChars), 240)
            let duration = minDuration + (maxDuration - minDuration) * (clampedLength / 240)
            let stepInterval = duration / Double(totalChars)

            var currentText = ""
            for character in fullText {
                currentText.append(character)
                updateDisplayedContent(for: last.id, text: currentText)
                try? await Task.sleep(nanoseconds: UInt64(stepInterval * 1_000_000_000))
                if Task.isCancelled { return }
            }

            completeAnimation(for: last.id, text: fullText)
        }
    }

    func updateDisplayedContent(for id: UUID, text: String) {
        if let index = aiVM.messages.firstIndex(where: { $0.id == id }) {
            aiVM.messages[index].displayedContent = text
        }
    }

    func completeAnimation(for id: UUID, text: String) {
        if let index = aiVM.messages.firstIndex(where: { $0.id == id }) {
            aiVM.messages[index].displayedContent = text
        }
        aiVM.animatingMessageID = nil
        isAnimatingAssistant = false
    }

    func consumeSelectedAction() {
        guard let current = selectedAction,
              let index = aiVM.pendingActions.firstIndex(of: current) else { return }
        aiVM.pendingActions.remove(at: index)
        if let next = aiVM.pendingActions.first {
            selectedAction = next
        }
    }
}

