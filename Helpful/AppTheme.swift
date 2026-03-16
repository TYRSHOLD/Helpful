import SwiftUI

// MARK: - Color Palette

enum AppColors {
    // Accent palette
    static let coral = Color(red: 0.99, green: 0.35, blue: 0.44)
    static let peach = Color(red: 1.00, green: 0.64, blue: 0.53)
    static let orange = Color(red: 1.00, green: 0.58, blue: 0.37)
    static let teal = Color(red: 0.16, green: 0.78, blue: 0.73)
    static let mint = Color(red: 0.44, green: 0.92, blue: 0.82)
    static let purple = Color(red: 0.60, green: 0.44, blue: 0.98)
    static let lavender = Color(red: 0.73, green: 0.57, blue: 1.00)
    static let skyBlue = Color(red: 0.33, green: 0.63, blue: 1.00)
    static let lightBlue = Color(red: 0.60, green: 0.80, blue: 1.00)
    static let yellow = Color(red: 0.99, green: 0.84, blue: 0.40)
    static let green = Color(red: 0.26, green: 0.85, blue: 0.48)

    // Surfaces
    static let background = Color(.systemBackground)
    static let elevatedBackground = Color(.secondarySystemBackground)
    static let subtleElevatedBackground = Color.white.opacity(0.06)

    // Legacy aliases (for existing usage)
    static let cardBackground = elevatedBackground
    static let secondaryBackground = elevatedBackground
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
}

// MARK: - Gradients

enum AppGradients {
    static let primary = LinearGradient(
        colors: [
            AppColors.coral.opacity(0.95),
            AppColors.orange.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let teal = LinearGradient(
        colors: [
            AppColors.teal.opacity(0.95),
            AppColors.mint.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purple = LinearGradient(
        colors: [
            AppColors.purple.opacity(0.95),
            AppColors.lavender.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let blue = LinearGradient(
        colors: [
            AppColors.skyBlue.opacity(0.95),
            AppColors.lightBlue.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let discover = LinearGradient(
        colors: [
            AppColors.purple.opacity(0.95),
            AppColors.skyBlue.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let green = LinearGradient(
        colors: [
            AppColors.green.opacity(0.95),
            AppColors.mint.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let authBackground = LinearGradient(
        colors: [
            AppColors.coral.opacity(0.18),
            AppColors.peach.opacity(0.10),
            AppColors.background
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppGradients.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(gradient)
                    .shadow(color: AppColors.coral.opacity(configuration.isPressed ? 0.15 : 0.28), radius: 16, x: 0, y: 10)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.elevatedBackground.opacity(0.9))
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.elevatedBackground.opacity(0.98))
                    .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
            )
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
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(gradient)
                    .overlay(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.softLight)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 14)
            )
    }
}

// MARK: - Category Helpers

enum TransactionCategory: String, CaseIterable, Codable {
    case income = "Income"
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
        case .income: return "arrow.down.left.circle.fill"
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
        case .income: return AppColors.green
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
