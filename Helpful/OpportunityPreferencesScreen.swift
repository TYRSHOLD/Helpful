import SwiftUI

struct OpportunityPreferencesScreen: View {

    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var selected: [String] = []
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Text("Choose what kinds of internships and scholarships you want to see in Discover. Leave everything off to see a broad mix.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Interest areas") {
                OpportunityPreferencesView(selected: $selected, major: auth.currentUser?.profile.major ?? "")
            }
        }
        .navigationTitle("Opportunity Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .fontWeight(.semibold)
                .disabled(isSaving)
            }
        }
        .onAppear {
            selected = auth.currentUser?.profile.opportunityInterests ?? []
        }
    }

    private func save() async {
        guard let user = auth.currentUser else { return }
        isSaving = true
        do {
            try await FirestoreService.shared.updateUserProfile(
                .init(
                    firstName: user.profile.firstName,
                    lastName: user.profile.lastName,
                    school: user.profile.school,
                    major: user.profile.major,
                    birthday: user.profile.birthday,
                    opportunityInterests: selected
                )
            )
            await auth.fetchUserProfile()
            dismiss()
        } catch {
            // Keep the screen open; ProfileView already logs errors similarly.
            print("Failed to save opportunity preferences:", error)
        }
        isSaving = false
    }
}

