import Foundation
import Observation

@Observable
@MainActor
final class AchievementViewModel {

    var data = AchievementData()
    var isLoading = false

    @ObservationIgnored
    private let service = FirestoreService.shared

    var streakDays: Int { data.streakDays }

    func load() async {
        isLoading = true
        do {
            data = try await service.fetchAchievements()
        } catch {
            print("[AchievementVM] Load failed: \(error)")
        }
        isLoading = false
    }

    func checkIn() async {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let last = data.lastCheckIn {
            let lastDay = cal.startOfDay(for: last)
            if lastDay == today {
                return
            }
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                data.streakDays += 1
            } else {
                data.streakDays = 1
            }
        } else {
            data.streakDays = 1
        }

        data.lastCheckIn = today
        await save()
    }

    func checkBadges(
        transactionCount: Int,
        goalsSaved: Double,
        completedGoals: Int,
        budgetUnderCount: Int,
        documentCount: Int,
        savedOpportunityCount: Int
    ) async {
        var changed = false

        func award(_ badge: Badge) {
            guard !data.hasBadge(badge) else { return }
            data.earnedBadges[badge.rawValue] = Date()
            changed = true
        }

        if transactionCount >= 1 { award(.firstTransaction) }
        if data.streakDays >= 7 { award(.weekStreak) }
        if data.streakDays >= 30 { award(.monthStreak) }
        if budgetUnderCount >= 1 { award(.budgetMaster) }
        if completedGoals >= 1 { award(.goalCrusher) }
        if goalsSaved >= 100 { award(.saverStarter) }
        if goalsSaved >= 1000 { award(.superSaver) }
        if documentCount >= 5 { award(.documentOrganizer) }
        if savedOpportunityCount >= 10 { award(.opportunityHunter) }

        if changed { await save() }
    }

    private func save() async {
        do {
            try await service.saveAchievements(data)
        } catch {
            print("[AchievementVM] Save failed: \(error)")
        }
    }
}
