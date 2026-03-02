import SwiftUI

struct AuthFlowView: View {
    @State private var showingSignUp = false

    var body: some View {
        NavigationStack {
            Group {
                if showingSignUp {
                    SignUpView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    LoginView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingSignUp)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showingSignUp ? "Log In" : "Sign Up") {
                        showingSignUp.toggle()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.coral)
                }
            }
        }
    }
}
