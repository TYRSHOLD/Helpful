import SwiftUI

struct SavedOpportunitiesView: View {

    @Environment(OpportunityViewModel.self) var vm
    @Environment(\.openURL) private var openURL
    @State private var searchText = ""

    private var filteredOpportunities: [Opportunity] {
        guard !searchText.isEmpty else { return vm.savedOpportunities }
        return vm.savedOpportunities.filter { opp in
            opp.title.localizedCaseInsensitiveContains(searchText) ||
            opp.employer.localizedCaseInsensitiveContains(searchText) ||
            opp.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if vm.savedOpportunities.isEmpty {
                ContentUnavailableView(
                    "No Saved Opportunities",
                    systemImage: "heart.slash",
                    description: Text("Swipe right on opportunities you like to save them here.")
                )
            } else {
                List {
                    ForEach(filteredOpportunities) { opp in
                        SavedOpportunityRow(opportunity: opp)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let url = URL(string: opp.applyURL), !opp.applyURL.isEmpty {
                                    openURL(url)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await vm.unsave(opp) }
                                } label: {
                                    Label("Remove", systemImage: "heart.slash.fill")
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, prompt: "Search saved opportunities")
    }
}

// MARK: - Row

private struct SavedOpportunityRow: View {

    let opportunity: Opportunity

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: opportunity.type.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(opportunity.type.color)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(opportunity.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                Text(opportunity.employer)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(opportunity.location, systemImage: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let savedAt = opportunity.savedAt {
                        Label {
                            Text(savedAt, style: .date)
                        } icon: {
                            Image(systemName: "heart.fill")
                        }
                        .font(.caption2)
                        .foregroundStyle(AppColors.coral)
                    }
                }
            }

            Spacer()

            typeBadge
        }
        .padding(12)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var typeBadge: some View {
        Text(opportunity.type.rawValue)
            .font(.caption2.bold())
            .foregroundStyle(opportunity.type.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(opportunity.type.color.opacity(0.12))
            .clipShape(Capsule())
    }
}
