import SwiftUI
import FirebaseCore

@main
struct HelpfulApp: App {

    @State private var auth = AuthViewModel()
    @AppStorage("darkMode") private var darkMode = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .preferredColorScheme(darkMode ? .dark : .light)
                .onAppear {
                    auth.startListening()
                }
                .task {
                    if auth.isAuthenticated {
                        await RecurringService.shared.processRecurring()
                    }
                }
        }
    }
}
