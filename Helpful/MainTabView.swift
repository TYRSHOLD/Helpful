import SwiftUI

struct MainTabView: View {

    @Binding var deeplinkTab: Int
    @State private var selectedTab = 0
    @State private var pendingMoreDestination: MoreDestination?
    
    init(deeplinkTab: Binding<Int> = .constant(-1)) {
        self._deeplinkTab = deeplinkTab
    }
    @State private var budgetVM = BudgetViewModel()
    @State private var transactionVM = TransactionViewModel()
    @State private var goalVM = GoalViewModel()
    @State private var documentVM = DocumentViewModel()
    @State private var opportunityVM = OpportunityViewModel()
    @State private var achievementVM = AchievementViewModel()
    @State private var aiInsightsVM = AIInsightsViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab, pendingMoreDestination: $pendingMoreDestination)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                BudgetView()
            }
            .tabItem { Label("Budgets", systemImage: "dollarsign.circle.fill") }
            .tag(1)

            NavigationStack {
                SpendingView(selectedTab: $selectedTab, pendingMoreDestination: $pendingMoreDestination)
            }
            .tabItem { Label("Spending", systemImage: "list.bullet.rectangle.fill") }
            .tag(2)

            NavigationStack {
                GoalsView()
            }
            .tabItem { Label("Goals", systemImage: "target") }
            .tag(3)

            NavigationStack {
                MoreView(pendingMoreDestination: $pendingMoreDestination)
            }
            .tabItem { Label("More", systemImage: "ellipsis.circle") }
            .tag(4)

        }
        .tint(AppColors.coral)
        .environment(budgetVM)
        .environment(transactionVM)
        .environment(goalVM)
        .environment(documentVM)
        .environment(opportunityVM)
        .environment(achievementVM)
        .environment(aiInsightsVM)
        .onAppear {
            budgetVM.startListening()
            transactionVM.startListening()
            goalVM.startListening()
            documentVM.startListening()
            opportunityVM.startListening()
            Task {
                await achievementVM.load()
                await achievementVM.checkIn()
            }
            
            // Handle deep link tab selection on app launch
            if deeplinkTab >= 0 && deeplinkTab <= 4 {
                selectedTab = deeplinkTab
                deeplinkTab = -1 // Reset after handling
            }
        }
        .onChange(of: deeplinkTab) { _, newValue in
            // Handle deep link tab selection when app is already running
            if newValue >= 0 && newValue <= 4 {
                selectedTab = newValue
                deeplinkTab = -1 // Reset after handling
            }
        }
        .onDisappear {
            budgetVM.stopListening()
            transactionVM.stopListening()
            goalVM.stopListening()
            documentVM.stopListening()
            opportunityVM.stopListening()
        }
    }
}
