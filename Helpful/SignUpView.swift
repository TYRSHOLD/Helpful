import SwiftUI

struct SignUpView: View {

    @Environment(AuthViewModel.self) var auth

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    private enum Field { case name, email, password, confirm }

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
                    Text("Create Account")
                        .font(.largeTitle.bold())

                    Text("Start your financial journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    StyledTextField(
                        icon: "person.fill",
                        placeholder: "Full Name",
                        text: $name,
                        submitLabel: .next
                    ) { focusedField = .email }
                    .focused($focusedField, equals: .name)

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
                        submitLabel: .next
                    ) { focusedField = .confirm }
                    .focused($focusedField, equals: .password)

                    StyledTextField(
                        icon: "lock.shield.fill",
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true,
                        submitLabel: .go
                    ) { signUp() }
                    .focused($focusedField, equals: .confirm)
                }

                if !password.isEmpty {
                    PasswordStrengthBar(password: password)
                }

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button {
                    signUp()
                } label: {
                    if auth.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
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

    private func signUp() {
        focusedField = nil
        Task {
            await auth.signUp(
                name: name,
                email: email,
                password: password,
                confirm: confirmPassword
            )
        }
    }
}

// MARK: - Password Strength Bar

struct PasswordStrengthBar: View {
    let password: String

    private var strength: (label: String, value: Double, color: Color) {
        let length = password.count
        if length < 6 { return ("Weak", 0.25, .red) }
        let hasUpper = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let score = [hasUpper, hasNumber, hasSpecial, length >= 10].filter(\.self).count
        switch score {
        case 0...1: return ("Fair", 0.5, AppColors.orange)
        case 2: return ("Good", 0.75, AppColors.yellow)
        default: return ("Strong", 1.0, AppColors.green)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.value, height: 6)
                        .animation(.easeOut, value: strength.value)
                }
            }
            .frame(height: 6)

            Text(strength.label)
                .font(.caption2)
                .foregroundStyle(strength.color)
        }
    }
}
