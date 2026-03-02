import SwiftUI

struct ProfileView: View {

    @Environment(AuthViewModel.self) var auth
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var school = ""
    @State private var major = ""
    @State private var notificationsEnabled = true
    @AppStorage("darkMode") private var darkMode = false
    @State private var isSaving = false
    @State private var showingSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(AppColors.coral)
                            Text(auth.userName)
                                .font(.title3.bold())
                            Text(auth.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Name") {
                    TextField("Full Name", text: $name)
                }

                Section("Profile") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("School", text: $school)
                    TextField("Major", text: $major)
                }

                Section {
                    NavigationLink(destination: AchievementsView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.orange)
                            Text("Achievements")
                        }
                    }
                }

                Section("Settings") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .tint(AppColors.coral)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            Task {
                                if enabled {
                                    let granted = await NotificationService.shared.requestPermission()
                                    if granted {
                                        NotificationService.shared.scheduleWeeklySummary()
                                    }
                                } else {
                                    NotificationService.shared.cancelAll()
                                }
                            }
                        }
                    Toggle("Dark Mode", isOn: $darkMode)
                        .tint(AppColors.coral)
                }

                Section {
                    Button("Save Changes") {
                        save()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.coral)
                    .disabled(isSaving)

                    Button("Sign Out", role: .destructive) {
                        auth.signOut()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if showingSaved {
                    savedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear(perform: loadCurrent)
        }
    }

    private var savedToast: some View {
        VStack {
            Text("Saved!")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.green)
                .clipShape(Capsule())
                .padding(.top, 8)
            Spacer()
        }
    }

    private func loadCurrent() {
        guard let user = auth.currentUser else { return }
        name = user.name
        firstName = user.profile.firstName
        lastName = user.profile.lastName
        school = user.profile.school
        major = user.profile.major
        notificationsEnabled = user.settings.notificationsEnabled
        darkMode = user.settings.darkMode
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let service = FirestoreService.shared
                try await service.updateUserName(name)
                try await service.updateUserProfile(
                    AppUser.UserProfile(
                        firstName: firstName,
                        lastName: lastName,
                        school: school,
                        major: major
                    )
                )
                try await service.updateUserSettings(
                    AppUser.UserSettings(
                        notificationsEnabled: notificationsEnabled,
                        darkMode: darkMode
                    )
                )
                await auth.fetchUserProfile()
                withAnimation { showingSaved = true }
                try? await Task.sleep(for: .seconds(2))
                withAnimation { showingSaved = false }
            } catch {
                print("Save failed:", error)
            }
            isSaving = false
        }
    }
}
