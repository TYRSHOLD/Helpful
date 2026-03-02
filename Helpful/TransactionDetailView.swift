import SwiftUI

struct TransactionDetailView: View {

    let transaction: Transaction

    @Environment(TransactionViewModel.self) var vm
    @Environment(BudgetViewModel.self) var budgetVM
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    categoryHeader
                    amountSection
                    detailsSection

                    if let receiptURL = transaction.receiptURL,
                       let url = URL(string: receiptURL) {
                        receiptSection(url: url)
                    }

                    deleteButton
                }
                .padding()
            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        if transaction.kind == .expense {
                            await budgetVM.subtractSpending(amount: transaction.amount)
                        }
                        await vm.delete(transaction)
                        dismiss()
                    }
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var categoryHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: transaction.parsedCategory.icon)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(transaction.parsedCategory.color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(transaction.parsedCategory.rawValue)
                .font(.title3.bold())

            if transaction.isRecurring {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(transaction.recurrenceInterval?.rawValue ?? "Recurring")
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.teal)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var amountSection: some View {
        Text(currencyString(transaction.amount))
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.coral)
    }

    private var detailsSection: some View {
        VStack(spacing: 14) {
            detailRow(icon: "calendar", label: "Date", value: formattedDate)

            if !transaction.note.isEmpty {
                detailRow(icon: "note.text", label: "Note", value: transaction.note)
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppColors.teal)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    private func receiptSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Receipt")
                .font(.headline)

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    Label("Could not load image", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Transaction")
            }
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.top, 8)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: transaction.date)
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
