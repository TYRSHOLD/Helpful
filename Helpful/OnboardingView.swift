import SwiftUI

struct OnboardingView: View {

    @Environment(AuthViewModel.self) var auth

    @State private var step = 0
    @State private var name = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var school = ""
    @State private var major = ""
    @State private var isSaving = false
    @State private var opportunityInterests: Set<String> = []

    var body: some View {
        TabView(selection: $step) {
            welcomeStep.tag(0)
            aboutYouStep.tag(1)
            opportunitiesStep.tag(2)
            allSetStep.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear {
            name = auth.userName
            if opportunityInterests.isEmpty {
                opportunityInterests = Set(suggestedInterests(from: major))
            }
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            Text("Welcome to Helpful!")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Your money companion.\nSet budgets, track spending, build savings goals, and keep important documents organized.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Get Started")
            }
            .buttonStyle(GradientButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(AppGradients.authBackground.ignoresSafeArea())
    }

    // MARK: - Step 2: About You

    private var aboutYouStep: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            Text("Tell us about you")
                .font(.system(.title, design: .rounded).weight(.bold))

            Text("This helps us personalize your experience.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                StyledTextField(
                    icon: "person.fill",
                    placeholder: "Your Name",
                    text: $name
                )

                DatePicker(selection: $birthday, in: ...Date(), displayedComponents: .date) {
                    HStack(spacing: 12) {
                        Image(systemName: "birthday.cake.fill")
                            .foregroundStyle(AppColors.coral)
                            .frame(width: 20)
                        Text("Birthday")
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.elevatedBackground.opacity(0.9))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                )

                StyledTextField(
                    icon: "building.columns.fill",
                    placeholder: "School (optional)",
                    text: $school
                )

                StyledTextField(
                    icon: "book.fill",
                    placeholder: "Major / Focus (optional)",
                    text: $major
                )
            }
            .padding(.horizontal, 28)

            Spacer()

            Button {
                if opportunityInterests.isEmpty {
                    opportunityInterests = Set(suggestedInterests(from: major))
                }
                withAnimation { step = 2 }
            } label: {
                Text("Continue")
            }
            .buttonStyle(GradientButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 3: Opportunities

    private var opportunitiesStep: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Text("What opportunities should we show you?")
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            Text("Pick a few interest areas. You can change this later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(OpportunityInterest.defaults, id: \.key) { item in
                        interestChip(
                            title: item.label,
                            isSelected: opportunityInterests.contains(item.key)
                        ) {
                            toggleInterest(item.key)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
            }

            HStack {
                Button {
                    withAnimation { step = 1 }
                } label: {
                    Text("Back")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation { step = 3 }
                } label: {
                    Text("Continue")
                }
                .buttonStyle(GradientButtonStyle())
                .padding(.horizontal, 28)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 3: All Set

    private var allSetStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppGradients.primary)

            Text("You're All Set!")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))

            Text("Let's start making your money work for you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                finish()
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Let's Go!")
                }
            }
            .buttonStyle(GradientButtonStyle())
            .disabled(isSaving)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(AppGradients.authBackground.ignoresSafeArea())
    }

    private func finish() {
        isSaving = true
        Task {
            do {
                let service = FirestoreService.shared
                if !name.isEmpty {
                    try await service.updateUserName(name)
                }
                try await service.updateUserProfile(
                    AppUser.UserProfile(
                        firstName: "",
                        lastName: "",
                        school: school,
                        major: major,
                        birthday: birthday,
                        opportunityInterests: Array(opportunityInterests).sorted()
                    )
                )
                try await service.completeOnboarding()
                let _ = await NotificationService.shared.requestPermission()
                NotificationService.shared.scheduleWeeklySummary()
                await auth.fetchUserProfile()
            } catch {
                print("Onboarding save failed:", error)
            }
            isSaving = false
        }
    }
}

private extension OnboardingView {
    struct OpportunityInterest {
        let key: String
        let label: String

        static let defaults: [OpportunityInterest] = [
            .init(key: "education", label: "Education"),
            .init(key: "healthcare", label: "Healthcare"),
            .init(key: "business", label: "Business"),
            .init(key: "computer_science", label: "Computer Science"),
            .init(key: "engineering", label: "Engineering"),
            .init(key: "design", label: "Design"),
            .init(key: "marketing", label: "Marketing"),
            .init(key: "psychology", label: "Psychology"),
            .init(key: "law", label: "Law"),
            .init(key: "social_work", label: "Social Work"),
            .init(key: "finance", label: "Finance"),
            .init(key: "science", label: "Science")
        ]
    }

    func toggleInterest(_ key: String) {
        if opportunityInterests.contains(key) {
            opportunityInterests.remove(key)
        } else {
            opportunityInterests.insert(key)
        }
    }

    func interestChip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.coral)
                }
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? AppColors.coral : .primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                        ? AppColors.coral.opacity(0.12)
                        : AppColors.elevatedBackground.opacity(0.95)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected ? AppColors.coral.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    func suggestedInterests(from major: String) -> [String] {
        let m = major.lowercased()
        if m.contains("education") || m.contains("teaching") { return ["education"] }
        if m.contains("nursing") || m.contains("health") || m.contains("medical") { return ["healthcare"] }
        if m.contains("computer") || m.contains("software") || m.contains("cs") { return ["computer_science"] }
        if m.contains("engineer") { return ["engineering"] }
        if m.contains("business") || m.contains("management") { return ["business"] }
        if m.contains("marketing") { return ["marketing"] }
        if m.contains("design") { return ["design"] }
        if m.contains("psych") { return ["psychology"] }
        if m.contains("law") || m.contains("legal") { return ["law"] }
        if m.contains("social") { return ["social_work"] }
        if m.contains("finance") || m.contains("account") { return ["finance"] }
        if m.contains("biology") || m.contains("chem") || m.contains("physics") { return ["science"] }
        return []
    }
}
