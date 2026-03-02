import SwiftUI

struct CostCalculatorView: View {

    @State private var items: [CostItem] = CostItem.defaults

    private var total: Double {
        items.reduce(0) { $0 + ($1.amount ?? 0) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                totalHeader

                List {
                    ForEach($items) { $item in
                        CostRow(item: $item)
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                }
                .listStyle(.insetGrouped)
            }

            Button {
                items.append(CostItem(label: "", icon: "ellipsis.circle.fill"))
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
    }

    private var totalHeader: some View {
        VStack(spacing: 4) {
            Text(currencyString(total))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.coral)
            Text("Estimated Semester Cost")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColors.secondaryBackground)
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Cost Item

private struct CostItem: Identifiable {
    let id = UUID()
    var label: String
    var icon: String
    var amountString = ""

    var amount: Double? { Double(amountString) }

    static let defaults: [CostItem] = [
        CostItem(label: "Tuition", icon: "building.columns.fill"),
        CostItem(label: "Books & Supplies", icon: "book.fill"),
        CostItem(label: "Housing", icon: "house.fill"),
        CostItem(label: "Food & Meals", icon: "fork.knife"),
        CostItem(label: "Transportation", icon: "car.fill"),
    ]
}

private struct CostRow: View {
    @Binding var item: CostItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(AppColors.teal)
                .frame(width: 24)

            if item.label.isEmpty {
                TextField("Label", text: $item.label)
                    .font(.subheadline)
            } else {
                Text(item.label)
                    .font(.subheadline)
            }

            Spacer()

            HStack(spacing: 2) {
                Text("$")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("0", text: $item.amountString)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.bold())
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 2)
    }
}
