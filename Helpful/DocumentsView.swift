import SwiftUI

struct DocumentsView: View {

    @Environment(DocumentViewModel.self) var vm
    @State private var showingAdd = false
    @State private var searchText = ""

    private var filteredDocuments: [UserDocument] {
        guard !searchText.isEmpty else { return vm.documents }
        return vm.documents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                if vm.documents.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text.fill",
                        description: Text("Tap + to upload your first document.")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(filteredDocuments) { doc in
                    DocumentRow(document: doc)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await vm.delete(doc) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                }
            }
            .listStyle(.plain)

            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AppGradients.primary)
                    .clipShape(Circle())
                    .shadow(color: AppColors.coral.opacity(0.4), radius: 8, y: 4)
            }
            .padding(20)
        }
        .navigationTitle("Documents")
        .searchable(text: $searchText, prompt: "Search documents")
        .sheet(isPresented: $showingAdd) {
            AddDocumentView()
        }
        .refreshable {
            await vm.load()
        }
    }
}

// MARK: - Document Row

private struct DocumentRow: View {
    let document: UserDocument

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconForFile(document.fileName))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColors.purple)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(document.uploadedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let url = URL(string: document.downloadURL) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.body)
                        .foregroundStyle(AppColors.teal)
                }
            }
        }
        .padding(12)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func iconForFile(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext.fill"
        case "jpg", "jpeg", "png", "heic": return "photo.fill"
        default: return "doc.fill"
        }
    }
}
