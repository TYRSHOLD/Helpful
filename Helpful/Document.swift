import Foundation
import FirebaseFirestore

struct UserDocument: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var fileName: String
    var downloadURL: String
    var uploadedAt: Date
    var storagePath: String?

    init(
        id: String? = nil,
        title: String = "",
        fileName: String = "",
        downloadURL: String = "",
        uploadedAt: Date = Date(),
        storagePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.downloadURL = downloadURL
        self.uploadedAt = uploadedAt
        self.storagePath = storagePath
    }
}
