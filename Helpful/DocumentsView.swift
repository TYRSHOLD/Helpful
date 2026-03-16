import SwiftUI
import QuickLook

struct DocumentsView: View {

    @Environment(DocumentViewModel.self) var vm
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var showingMissingAlert = false
    @State private var missingDocument: UserDocument?
    @State private var previewURL: URL?
    @State private var showingPreview = false
    @Environment(\.openURL) private var openURL

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
                        description: Text("Tap + to upload a receipt, bill, statement, warranty, or anything you want to keep handy.")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(filteredDocuments) { doc in
                    DocumentRow(document: doc) { selected in
                        openDocument(selected)
                    }
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
                .environment(vm)
        }
        .refreshable {
            await vm.load()
        }
        .sheet(isPresented: $showingPreview) {
            if let url = previewURL {
                DocumentQuickLookPreview(url: url)
            }
        }
        .alert("File not available", isPresented: $showingMissingAlert) {
            Button("Remove from list", role: .destructive) {
                if let doc = missingDocument {
                    Task { await vm.removeBroken(doc) }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This file is no longer available in storage. You can remove it from your list.")
        }
    }

    private func openDocument(_ document: UserDocument) {
        guard let url = URL(string: document.downloadURL) else { return }
        Task {
            let exists = await urlExists(url)
            await MainActor.run {
                if !exists {
                    missingDocument = document
                    showingMissingAlert = true
                }
            }
            guard exists else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(document.fileName.isEmpty ? UUID().uuidString : document.fileName)
                try data.write(to: tempURL, options: .atomic)
                await MainActor.run {
                    previewURL = tempURL
                    showingPreview = true
                }
            } catch {
                await MainActor.run {
                    missingDocument = document
                    showingMissingAlert = true
                }
            }
        }
    }

    private func urlExists(_ url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return (200...299).contains(http.statusCode)
            }
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Document Row

private struct DocumentRow: View {
    let document: UserDocument
    let onOpen: (UserDocument) -> Void

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

            Button {
                onOpen(document)
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .font(.body)
                    .foregroundStyle(AppColors.teal)
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

// MARK: - Quick Look wrapper

private struct DocumentQuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) { }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
