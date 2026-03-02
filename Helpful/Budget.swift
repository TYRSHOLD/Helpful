import Foundation
import FirebaseFirestore

struct Budget: Codable, Identifiable {
    @DocumentID var id: String?
    var month: String
    var total: Double
    var spent: Double
    var createdAt: Date

    var remaining: Double { total - spent }
    var progress: Double { total > 0 ? min(spent / total, 1.0) : 0 }
}
