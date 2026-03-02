import SwiftUI

struct AddBudgetView: View {

    @Environment(BudgetViewModel.self) var vm
    @Environment(\.dismiss) private var dismiss

    @State private var month = ""
    @State private var totalString = ""

    private let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    var body: some View {
        NavigationStack {
            Form {
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
}
