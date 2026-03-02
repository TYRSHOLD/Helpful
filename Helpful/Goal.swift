import Foundation
import FirebaseFirestore

struct Goal: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var emoji: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date

    var progress: Double { targetAmount > 0 ? min(currentAmount / targetAmount, 1.0) : 0 }
    var remaining: Double { max(targetAmount - currentAmount, 0) }

    init(id: String? = nil, title: String, emoji: String = "🎯", targetAmount: Double, currentAmount: Double = 0, deadline: Date) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        emoji = (try? container.decode(String.self, forKey: .emoji)) ?? "🎯"
        targetAmount = (try? container.decode(Double.self, forKey: .targetAmount)) ?? 0
        currentAmount = (try? container.decode(Double.self, forKey: .currentAmount)) ?? 0
        deadline = (try? container.decode(Date.self, forKey: .deadline)) ?? Date()
    }
}
