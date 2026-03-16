import SwiftUI

struct AddBudgetView: View {

    @Environment(BudgetViewModel.self) var vm
    @Environment(\.dismiss) private var dismiss

    @State private var month = ""
    @State private var totalString = ""
    @State private var selectedTemplate: BudgetTemplate?

    private let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Starter templates") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(BudgetTemplate.defaults) { template in
                                Button {
                                    apply(template)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.title)
                                            .font(.subheadline.bold())
                                        Text(currencyString(template.total))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(AppColors.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay {
                                        if selectedTemplate?.id == template.id {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(AppColors.coral, lineWidth: 1.5)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Text("Pick one to pre-fill a monthly budget total. You can always edit the amount.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Month", selection: $month) {
                    Text("Select a month").tag("")
                    ForEach(months, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }

                HStack {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("Budget Amount", text: $totalString)
                        .keyboardType(.decimalPad)
                }

                if let template = selectedTemplate {
                    Section("Suggested breakdown (optional)") {
                        ForEach(template.allocations) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(currencyString(template.total * item.percent))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text("This is just a starting point—Helpful currently tracks a single monthly total budget.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(month.isEmpty || totalString.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard let total = Double(totalString), total > 0 else { return }
        Task {
            await vm.add(month: month, total: total)
            dismiss()
        }
    }

    private func apply(_ template: BudgetTemplate) {
        selectedTemplate = template
        totalString = String(format: "%.0f", template.total)
        if month.isEmpty {
            month = currentMonthName()
        }
    }

    private func currentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

private struct BudgetTemplate: Identifiable {
    struct Allocation: Identifiable {
        let id = UUID()
        let category: String
        let percent: Double
    }

    let id = UUID()
    let title: String
    let total: Double
    let allocations: [Allocation]

    static let defaults: [BudgetTemplate] = [
        .init(
            title: "Essentials",
            total: 800,
            allocations: [
                .init(category: "Housing & utilities", percent: 0.40),
                .init(category: "Groceries", percent: 0.18),
                .init(category: "Transportation", percent: 0.10),
                .init(category: "Bills & subscriptions", percent: 0.12),
                .init(category: "Fun money", percent: 0.10),
                .init(category: "Savings", percent: 0.10)
            ]
        ),
        .init(
            title: "Balanced",
            total: 1200,
            allocations: [
                .init(category: "Housing & utilities", percent: 0.38),
                .init(category: "Groceries", percent: 0.16),
                .init(category: "Transportation", percent: 0.10),
                .init(category: "Bills & subscriptions", percent: 0.10),
                .init(category: "Dining & fun", percent: 0.16),
                .init(category: "Savings", percent: 0.10)
            ]
        ),
        .init(
            title: "Saver",
            total: 1500,
            allocations: [
                .init(category: "Housing & utilities", percent: 0.35),
                .init(category: "Groceries", percent: 0.14),
                .init(category: "Transportation", percent: 0.08),
                .init(category: "Bills & subscriptions", percent: 0.10),
                .init(category: "Dining & fun", percent: 0.13),
                .init(category: "Savings", percent: 0.20)
            ]
        )
    ]
}
