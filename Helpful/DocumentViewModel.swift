import Foundation
import Observation
import FirebaseFirestore

@Observable
@MainActor
final class DocumentViewModel {

    var documents: [UserDocument] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private let service = FirestoreService.shared

    func startListening() {
        listener?.remove()
        do {
            listener = try service.listenToDocuments { [weak self] docs in
                Task { @MainActor in
                    self?.documents = docs
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func load() async {
        isLoading = true
        do {
            documents = try await service.fetchDocuments()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func upload(data: Data, fileName: String, title: String) async {
        isLoading = true
        do {
            _ = try await service.uploadDocument(data: data, fileName: fileName, title: title)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ document: UserDocument) async {
        guard document.id != nil else {
            print("[DocumentVM] Cannot delete: document.id is nil")
            return
        }
        documents.removeAll { $0.id == document.id }
        do {
            try await service.deleteDocument(doc: document)
        } catch {
            print("[DocumentVM] Delete failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            await load()
        }
    }
}
