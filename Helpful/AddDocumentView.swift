import SwiftUI
import UniformTypeIdentifiers

struct AddDocumentView: View {

    @Environment(DocumentViewModel.self) var vm
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var showingFilePicker = false
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section("Document Title") {
                    TextField("e.g. Fall 2026 Syllabus", text: $title)
                }

                Section("File") {
                    if let name = selectedFileName {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(AppColors.purple)
                            Text(name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Button("Change") {
                                showingFilePicker = true
                            }
                            .font(.caption)
                        }
                    } else {
                        Button {
                            showingFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                    .foregroundStyle(AppColors.coral)
                                Text("Choose a File")
                                    .foregroundStyle(AppColors.coral)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") { upload() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || selectedFileData == nil || isUploading)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                handleFileResult(result)
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Uploading...")
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else {
            Task { @MainActor in
                errorMessage = "Could not access the selected file."
            }
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            let name = url.lastPathComponent
            Task { @MainActor in
                selectedFileData = data
                selectedFileName = name
                errorMessage = nil
            }
        } catch {
            Task { @MainActor in
                errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }

    private func upload() {
        guard let data = selectedFileData, let fileName = selectedFileName else { return }
        isUploading = true
        errorMessage = nil
        let uniqueName = "\(UUID().uuidString)_\(fileName)"
        Task { @MainActor in
            await vm.upload(data: data, fileName: uniqueName, title: title)
            isUploading = false
            if vm.errorMessage != nil {
                errorMessage = vm.errorMessage
            } else {
                dismiss()
            }
        }
    }
}
