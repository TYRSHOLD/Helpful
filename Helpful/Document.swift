import Foundation
import FirebaseFirestore

struct UserDocument: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var fileName: String
    var downloadURL: String
    var uploadedAt: Date

    init(id: String? = nil, title: String = "", fileName: String = "", downloadURL: String = "", uploadedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.downloadURL = downloadURL
        self.uploadedAt = uploadedAt
    }
}
