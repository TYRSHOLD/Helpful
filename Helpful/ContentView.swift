import SwiftUI

struct ContentView: View {

    @Environment(AuthViewModel.self) var auth
    @AppStorage("deeplinkTab") private var deeplinkTab: Int = -1

    var body: some View {
        Group {
            if auth.isAuthenticated {
                if auth.currentUser?.hasCompletedOnboarding == true {
                    MainTabView(deeplinkTab: $deeplinkTab)
                } else {
                    OnboardingView()
                }
            } else {
                AuthFlowView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: auth.currentUser?.hasCompletedOnboarding)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "helpful",
              url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let tabParam = queryItems.first(where: { $0.name == "tab" })?.value else {
            return
        }
        
        // Map tab names to tab indices
        let tabMap: [String: Int] = [
            "spending": 2,
            "goals": 3,
            "budgets": 1,
            "home": 0
        ]
        
        if let tabIndex = tabMap[tabParam.lowercased()] {
            deeplinkTab = tabIndex
        }
    }
}
