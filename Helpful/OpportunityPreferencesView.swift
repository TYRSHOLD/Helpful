import SwiftUI

struct OpportunityPreferencesView: View {

    @Binding var selected: [String]
    let major: String

    @State private var local: Set<String> = []

    var body: some View {
        Form {
            Section {
                Text("Choose the kinds of internships and scholarships you want to see. Leave everything off to see a broad mix.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Interest areas") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Interests.defaults, id: \.key) { item in
                        chip(title: item.label, isSelected: local.contains(item.key)) {
                            toggle(item.key)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Suggest based on my major") {
                    let suggestions = suggestedInterests(from: major)
                    if suggestions.isEmpty {
                        local = []
                    } else {
                        local = Set(suggestions)
                    }
                }
                .foregroundStyle(AppColors.coral)

                Button("Clear selection") {
                    local = []
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Opportunity Interests")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            local = Set(selected)
        }
        .onChange(of: local) { _, newValue in
            selected = Array(newValue).sorted()
        }
    }

    private struct Interests {
        let key: String
        let label: String

        static let defaults: [Interests] = [
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

    private func toggle(_ key: String) {
        if local.contains(key) {
            local.remove(key)
        } else {
            local.insert(key)
        }
    }

    private func chip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
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
            .background(isSelected ? AppColors.coral.opacity(0.10) : AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func suggestedInterests(from major: String) -> [String] {
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

