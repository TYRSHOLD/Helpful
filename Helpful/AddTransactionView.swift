import SwiftUI
import PhotosUI

struct AddTransactionView: View {

    @Environment(TransactionViewModel.self) var vm
    @Environment(BudgetViewModel.self) var budgetVM
    @Environment(\.dismiss) private var dismiss

    @State private var amountString = ""
    @State private var category: TransactionCategory = .food
    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var isUploading = false
    @State private var isRecurring = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var kind: TransactionKind = .expense

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Type") {
                    Picker("Type", selection: $kind) {
                        Text("Expense").tag(TransactionKind.expense)
                        Text("Income").tag(TransactionKind.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Note (optional)") {
                    TextField("What was this for?", text: $note)
                }

                Section("Recurring") {
                    Toggle("Repeat this transaction", isOn: $isRecurring)
                        .tint(AppColors.coral)
                    if isRecurring {
                        Picker("Frequency", selection: $recurrenceInterval) {
                            ForEach(RecurrenceInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Receipt (optional)") {
                    if let receiptImage {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button("Remove Photo", role: .destructive) {
                            self.receiptImage = nil
                            self.selectedPhoto = nil
                        }
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            receiptImage == nil ? "Add Receipt Photo" : "Change Photo",
                            systemImage: "camera.fill"
                        )
                        .foregroundStyle(AppColors.coral)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(amountString.isEmpty || isUploading)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        receiptImage = image
                    }
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let amount = Double(amountString), amount > 0 else { return }
        isUploading = true
        Task {
            var receiptURL: String?
            if let image = receiptImage,
               let imageData = image.jpegData(compressionQuality: 0.7) {
                do {
                    receiptURL = try await FirestoreService.shared.uploadReceipt(imageData: imageData)
                } catch {
                    print("Receipt upload failed:", error)
                }
            }

            await vm.add(
                amount: amount,
                category: category,
                note: note,
                receiptURL: receiptURL,
                isRecurring: isRecurring,
                recurrenceInterval: isRecurring ? recurrenceInterval : nil,
                kind: kind
            )
            if kind == .expense {
                await budgetVM.addSpending(amount: amount)
            }
            isUploading = false
            dismiss()
        }
    }
}
