import SwiftUI

struct LoginView: View {

    @Environment(AuthViewModel.self) var auth

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        @Bindable var auth = auth

        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                Image("Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                VStack(spacing: 6) {
                    Text("Welcome Back")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    StyledTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        submitLabel: .next
                    ) { focusedField = .password }
                    .focused($focusedField, equals: .email)

                    StyledTextField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        submitLabel: .go
                    ) { login() }
                    .focused($focusedField, equals: .password)
                }

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button {
                    login()
                } label: {
                    if auth.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Log In")
                    }
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(auth.isLoading)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .background(AppGradients.authBackground.ignoresSafeArea())
        .onTapGesture { focusedField = nil }
    }

    private func login() {
        focusedField = nil
        Task { await auth.login(email: email, password: password) }
    }
}
