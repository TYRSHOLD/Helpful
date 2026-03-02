import SwiftUI

struct AchievementsView: View {

    @Environment(AchievementViewModel.self) var vm

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                streakCard
                badgeGrid
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    vm.streakDays >= 7
                    ? LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.streakDays)-day streak")
                    .font(.title2.bold())
                Text("Keep opening the app daily!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Badge.allCases) { badge in
                badgeCell(badge)
            }
        }
    }

    private func badgeCell(_ badge: Badge) -> some View {
        let earned = vm.data.hasBadge(badge)
        return VStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 32))
                .foregroundStyle(earned ? badge.color : Color.gray.opacity(0.4))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(earned ? badge.color.opacity(0.15) : Color.gray.opacity(0.08))
                )

            Text(badge.rawValue)
                .font(.caption2.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(earned ? .primary : .secondary)

            if let date = vm.data.dateEarned(badge) {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text(badge.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(earned ? 1 : 0.65)
    }
}
