import Foundation
import FirebaseFirestore

enum RecurrenceInterval: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"

    var calendarComponent: (Calendar.Component, Int) {
        switch self {
        case .weekly: return (.day, 7)
        case .biweekly: return (.day, 14)
        case .monthly: return (.month, 1)
        }
    }
}

enum TransactionKind: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
}

struct Transaction: Codable, Identifiable {
    @DocumentID var id: String?
    var amount: Double
    var category: String
    var note: String
    var date: Date
    var receiptURL: String?
    var isRecurring: Bool
    var recurrenceInterval: RecurrenceInterval?
    var kind: TransactionKind
    var tags: [String]

    var parsedCategory: TransactionCategory {
        TransactionCategory(rawValue: category) ?? .other
    }

    init(
        id: String? = nil,
        amount: Double,
        category: String,
        note: String,
        date: Date,
        receiptURL: String? = nil,
        isRecurring: Bool = false,
        recurrenceInterval: RecurrenceInterval? = nil,
        kind: TransactionKind = .expense,
        tags: [String] = []
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
        self.receiptURL = receiptURL
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.kind = kind
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        amount = (try? container.decode(Double.self, forKey: .amount)) ?? 0
        category = (try? container.decode(String.self, forKey: .category)) ?? "Other"
        note = (try? container.decode(String.self, forKey: .note)) ?? ""
        date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        receiptURL = try? container.decode(String.self, forKey: .receiptURL)
        isRecurring = (try? container.decode(Bool.self, forKey: .isRecurring)) ?? false
        recurrenceInterval = try? container.decode(RecurrenceInterval.self, forKey: .recurrenceInterval)
        kind = (try? container.decode(TransactionKind.self, forKey: .kind)) ?? .expense
        tags = (try? container.decode([String].self, forKey: .tags)) ?? []
    }
}

