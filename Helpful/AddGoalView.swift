import SwiftUI

struct AddGoalView: View {

    @Environment(GoalViewModel.self) var vm
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var emoji = "🎯"
    @State private var targetAmountString = ""
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    private let emojiOptions = ["🎯", "🎓", "💻", "✈️", "🚗", "🏠", "💰", "📱", "👟", "🎸", "📚", "💍", "🏋️", "🎮", "☕️", "🛍️"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Pick an Emoji") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Text(e)
                                    .font(.title)
                                    .frame(width: 48, height: 48)
                                    .background(emoji == e ? AppColors.coral.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(emoji == e ? AppColors.coral : .clear, lineWidth: 2)
                                    )
                                    .onTapGesture { emoji = e }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("What are you saving for?") {
                    TextField("e.g. New Laptop", text: $title)
                }

                Section("Target Amount") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $targetAmountString)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                    }
                }

                Section("Deadline") {
                    DatePicker(
                        "Target Date",
                        selection: $deadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || targetAmountString.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let target = Double(targetAmountString), target > 0 else { return }
        Task {
            await vm.add(title: title, emoji: emoji, targetAmount: target, deadline: deadline)
            dismiss()
        }
    }
}
