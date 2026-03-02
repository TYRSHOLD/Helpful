import SwiftUI

// MARK: - Color Palette

enum AppColors {
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let peach = Color(red: 1.0, green: 0.68, blue: 0.52)
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.30)
    static let teal = Color(red: 0.20, green: 0.78, blue: 0.76)
    static let mint = Color(red: 0.40, green: 0.90, blue: 0.80)
    static let purple = Color(red: 0.58, green: 0.40, blue: 0.98)
    static let lavender = Color(red: 0.72, green: 0.55, blue: 1.0)
    static let skyBlue = Color(red: 0.30, green: 0.60, blue: 1.0)
    static let lightBlue = Color(red: 0.55, green: 0.78, blue: 1.0)
    static let yellow = Color(red: 1.0, green: 0.82, blue: 0.32)
    static let green = Color(red: 0.30, green: 0.85, blue: 0.48)

    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
}

// MARK: - Gradients

enum AppGradients {
    static let primary = LinearGradient(
        colors: [AppColors.coral, AppColors.orange],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let teal = LinearGradient(
        colors: [AppColors.teal, AppColors.mint],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let purple = LinearGradient(
        colors: [AppColors.purple, AppColors.lavender],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let blue = LinearGradient(
        colors: [AppColors.skyBlue, AppColors.lightBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let discover = LinearGradient(
        colors: [AppColors.purple, AppColors.skyBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let authBackground = LinearGradient(
        colors: [
            AppColors.coral.opacity(0.15),
            AppColors.peach.opacity(0.10),
            Color(.systemBackground)
        ],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppGradients.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Styled Text Field

struct StyledTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.coral)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
            }
        }
        .padding(14)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Gradient Card

struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Category Helpers

enum TransactionCategory: String, CaseIterable, Codable {
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case bills = "Bills"
    case education = "Education"
    case health = "Health"
    case other = "Other"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .shopping: return "bag.fill"
        case .bills: return "doc.text.fill"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return AppColors.orange
        case .transport: return AppColors.skyBlue
        case .entertainment: return AppColors.purple
        case .shopping: return AppColors.coral
        case .bills: return AppColors.teal
        case .education: return AppColors.lavender
        case .health: return AppColors.green
        case .other: return AppColors.yellow
        }
    }
}
