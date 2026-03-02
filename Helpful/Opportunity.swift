import Foundation
import SwiftUI
import FirebaseFirestore

enum OpportunityType: String, Codable, CaseIterable {
    case scholarship = "Scholarship"
    case internship = "Internship"

    var icon: String {
        switch self {
        case .scholarship: return "graduationcap.fill"
        case .internship: return "briefcase.fill"
        }
    }

    var color: Color {
        switch self {
        case .scholarship: return AppColors.purple
        case .internship: return AppColors.teal
        }
    }
}

struct Opportunity: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var title: String
    var employer: String
    var descriptionText: String
    var location: String
    var type: OpportunityType
    var applyURL: String
    var datePosted: Date
    var savedAt: Date?

    var externalId: String

    init(
        id: String? = nil,
        title: String,
        employer: String,
        descriptionText: String,
        location: String,
        type: OpportunityType,
        applyURL: String,
        datePosted: Date,
        savedAt: Date? = nil,
        externalId: String
    ) {
        self.id = id
        self.title = title
        self.employer = employer
        self.descriptionText = descriptionText
        self.location = location
        self.type = type
        self.applyURL = applyURL
        self.datePosted = datePosted
        self.savedAt = savedAt
        self.externalId = externalId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        employer = (try? container.decode(String.self, forKey: .employer)) ?? ""
        descriptionText = (try? container.decode(String.self, forKey: .descriptionText)) ?? ""
        location = (try? container.decode(String.self, forKey: .location)) ?? ""
        type = (try? container.decode(OpportunityType.self, forKey: .type)) ?? .internship
        applyURL = (try? container.decode(String.self, forKey: .applyURL)) ?? ""
        datePosted = (try? container.decode(Date.self, forKey: .datePosted)) ?? Date()
        savedAt = try? container.decode(Date.self, forKey: .savedAt)
        externalId = (try? container.decode(String.self, forKey: .externalId)) ?? UUID().uuidString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(externalId)
    }

    static func == (lhs: Opportunity, rhs: Opportunity) -> Bool {
        lhs.externalId == rhs.externalId
    }
}
