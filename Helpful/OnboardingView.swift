import SwiftUI

struct OnboardingView: View {

    @Environment(AuthViewModel.self) var auth

    @State private var step = 0
    @State private var name = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var school = ""
    @State private var major = ""
    @State private var isSaving = false

    var body: some View {
        TabView(selection: $step) {
            welcomeStep.tag(0)
            aboutYouStep.tag(1)
            allSetStep.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear {
            name = auth.userName
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

            Text("Your all-in-one student companion.\nManage budgets, track spending, hit savings goals, organize documents, and plan your semester.")
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
                .font(.title.bold())

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
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                StyledTextField(
                    icon: "building.columns.fill",
                    placeholder: "School",
                    text: $school
                )

                StyledTextField(
                    icon: "book.fill",
                    placeholder: "Major",
                    text: $major
                )
            }
            .padding(.horizontal, 28)

            Spacer()

            Button {
                withAnimation { step = 2 }
            } label: {
                Text("Continue")
            }
            .buttonStyle(GradientButtonStyle())
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
                .font(.largeTitle.bold())

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
                        birthday: birthday
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
