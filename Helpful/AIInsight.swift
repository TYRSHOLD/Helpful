import Foundation

enum InsightCategory: String, Codable {
    case warning
    case tip
    case celebration
}

struct AIInsight: Identifiable, Codable {
    let id: UUID
    let icon: String
    let title: String
    let body: String
    let category: InsightCategory
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        icon: String,
        title: String,
        body: String,
        category: InsightCategory,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.category = category
        self.generatedAt = generatedAt
    }
}

