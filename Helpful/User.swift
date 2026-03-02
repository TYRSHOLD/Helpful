import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var createdAt: Date
    var hasCompletedOnboarding: Bool
    var profile: UserProfile
    var settings: UserSettings

    struct UserProfile: Codable {
        var firstName: String
        var lastName: String
        var school: String
        var major: String
        var birthday: Date?

        static let empty = UserProfile(firstName: "", lastName: "", school: "", major: "", birthday: nil)
    }

    struct UserSettings: Codable {
        var notificationsEnabled: Bool
        var darkMode: Bool

        static let defaults = UserSettings(notificationsEnabled: true, darkMode: false)
    }

    init(id: String? = nil, name: String = "", email: String = "", createdAt: Date = Date(), hasCompletedOnboarding: Bool = false, profile: UserProfile = .empty, settings: UserSettings = .defaults) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.profile = profile
        self.settings = settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        email = (try? container.decode(String.self, forKey: .email)) ?? ""
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        hasCompletedOnboarding = (try? container.decode(Bool.self, forKey: .hasCompletedOnboarding)) ?? false
        profile = (try? container.decode(UserProfile.self, forKey: .profile)) ?? .empty
        settings = (try? container.decode(UserSettings.self, forKey: .settings)) ?? .defaults
    }
}
