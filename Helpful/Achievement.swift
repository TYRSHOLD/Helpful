import Foundation
import SwiftUI

enum Badge: String, Codable, CaseIterable, Identifiable {
    case firstTransaction = "First Transaction"
    case weekStreak = "7-Day Streak"
    case monthStreak = "30-Day Streak"
    case budgetMaster = "Budget Master"
    case goalCrusher = "Goal Crusher"
    case saverStarter = "Saver Starter"
    case superSaver = "Super Saver"
    case documentOrganizer = "Doc Organizer"
    case opportunityHunter = "Opportunity Hunter"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .firstTransaction: return "creditcard.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "flame.circle.fill"
        case .budgetMaster: return "shield.checkered"
        case .goalCrusher: return "target"
        case .saverStarter: return "banknote.fill"
        case .superSaver: return "dollarsign.circle.fill"
        case .documentOrganizer: return "doc.on.doc.fill"
        case .opportunityHunter: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .firstTransaction: return AppColors.coral
        case .weekStreak: return AppColors.orange
        case .monthStreak: return .red
        case .budgetMaster: return AppColors.teal
        case .goalCrusher: return AppColors.green
        case .saverStarter: return AppColors.skyBlue
        case .superSaver: return AppColors.purple
        case .documentOrganizer: return AppColors.lavender
        case .opportunityHunter: return AppColors.purple
        }
    }

    var description: String {
        switch self {
        case .firstTransaction: return "Log your first transaction"
        case .weekStreak: return "Use the app 7 days in a row"
        case .monthStreak: return "Use the app 30 days in a row"
        case .budgetMaster: return "Stay under budget for a month"
        case .goalCrusher: return "Complete a savings goal"
        case .saverStarter: return "Save $100 toward goals"
        case .superSaver: return "Save $1,000 toward goals"
        case .documentOrganizer: return "Upload 5 documents"
        case .opportunityHunter: return "Save 10 opportunities"
        }
    }
}

struct AchievementData: Codable {
    var streakDays: Int
    var lastCheckIn: Date?
    var earnedBadges: [String: Date] // badge rawValue -> date earned

    init(streakDays: Int = 0, lastCheckIn: Date? = nil, earnedBadges: [String: Date] = [:]) {
        self.streakDays = streakDays
        self.lastCheckIn = lastCheckIn
        self.earnedBadges = earnedBadges
    }

    func hasBadge(_ badge: Badge) -> Bool {
        earnedBadges[badge.rawValue] != nil
    }

    func dateEarned(_ badge: Badge) -> Date? {
        earnedBadges[badge.rawValue]
    }
}
