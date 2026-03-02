import SwiftUI

struct OpportunitiesTabView: View {

    @State private var selectedSection = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSection) {
                Text("Discover").tag(0)
                Text("Saved").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedSection == 0 {
                OpportunityDiscoverView()
            } else {
                SavedOpportunitiesView()
            }
        }
        .navigationTitle("Opportunities")
    }
}
