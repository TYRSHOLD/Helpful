import SwiftUI

struct MoreView: View {

    @Binding var pendingMoreDestination: MoreDestination?
    @State private var presentingDestination: MoreDestination?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionTitle("Money")
                    .padding(.horizontal, 16)

                grid(columns: 2) {
                    NavigationLink { AIChatView() } label: {
                        moreCard(title: "Helpful AI", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    NavigationLink { TransactionsView() } label: {
                        moreCard(title: "Transactions", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink { DocumentsView() } label: {
                        moreCard(title: "Docs", systemImage: "doc.text.fill")
                    }
                    NavigationLink { RecurringTransactionsView() } label: {
                        moreCard(title: "Recurring", systemImage: "arrow.triangle.2.circlepath")
                    }
                    NavigationLink { RemindersView() } label: {
                        moreCard(title: "Reminders", systemImage: "bell.badge.fill")
                    }
                }
                .padding(.horizontal, 16)

                sectionTitle("Student tools (optional)")
                    .padding(.horizontal, 16)

                grid(columns: 2) {
                    NavigationLink { SemesterCalcView() } label: {
                        moreCard(title: "Tools", systemImage: "wrench.and.screwdriver.fill")
                    }
                    NavigationLink { OpportunitiesTabView() } label: {
                        moreCard(title: "Discover", systemImage: "sparkles")
                    }
                    NavigationLink {
                        OpportunityPreferencesScreen()
                    } label: {
                        moreCard(title: "Preferences", systemImage: "slider.horizontal.3")
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("More")
        .onAppear { consumePendingDestinationIfNeeded() }
        .onChange(of: pendingMoreDestination) { _, _ in
            consumePendingDestinationIfNeeded()
        }
        .sheet(item: $presentingDestination) { dest in
            NavigationStack {
                switch dest {
                case .helpfulAI:
                    AIChatView()
                case .documents:
                    DocumentsView()
                case .tools:
                    SemesterCalcView()
                case .discover:
                    OpportunitiesTabView()
                case .transactions:
                    TransactionsView()
                case .recurring:
                    RecurringTransactionsView()
                case .reminders:
                    RemindersView()
                }
            }
        }
    }

    private func moreCard(title: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.elevatedBackground.opacity(0.9))
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
            }
            Text(title)
                .font(.subheadline.bold())
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.98))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private func grid(columns: Int, @ViewBuilder content: () -> some View) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: columns),
            spacing: 16
        ) {
            content()
        }
    }

    private func consumePendingDestinationIfNeeded() {
        guard let dest = pendingMoreDestination else { return }
        pendingMoreDestination = nil
        presentingDestination = dest
    }
}

