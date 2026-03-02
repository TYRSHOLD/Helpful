import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@MainActor
final class FirestoreService {

    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    private var uid: String? { Auth.auth().currentUser?.uid }

    private func userDoc() throws -> DocumentReference {
        guard let uid else { throw ServiceError.notAuthenticated }
        return db.collection("users").document(uid)
    }

    // MARK: - User Profile

    func createUserProfile(uid: String, name: String, email: String) async throws {
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": Timestamp(),
            "hasCompletedOnboarding": false,
            "profile": [
                "firstName": "",
                "lastName": "",
                "school": "",
                "major": ""
            ],
            "settings": [
                "notificationsEnabled": true,
                "darkMode": false
            ]
        ]
        try await db.collection("users").document(uid).setData(data)
    }

    func fetchUser(uid: String) async throws -> AppUser? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: AppUser.self)
    }

    func updateUserProfile(_ profile: AppUser.UserProfile) async throws {
        let ref = try userDoc()
        var data: [String: Any] = [
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "school": profile.school,
            "major": profile.major
        ]
        if let birthday = profile.birthday {
            data["birthday"] = Timestamp(date: birthday)
        }
        try await ref.updateData(["profile": data])
    }

    func updateUserSettings(_ settings: AppUser.UserSettings) async throws {
        let ref = try userDoc()
        try await ref.updateData([
            "settings": [
                "notificationsEnabled": settings.notificationsEnabled,
                "darkMode": settings.darkMode
            ]
        ])
    }

    func updateUserName(_ name: String) async throws {
        let ref = try userDoc()
        try await ref.updateData(["name": name])
    }

    func completeOnboarding() async throws {
        let ref = try userDoc()
        try await ref.updateData(["hasCompletedOnboarding": true])
    }

    // MARK: - Budgets

    func addBudget(_ budget: Budget) async throws {
        let ref = try userDoc()
        let data: [String: Any] = [
            "month": budget.month,
            "total": budget.total,
            "spent": budget.spent,
            "createdAt": Timestamp(date: budget.createdAt)
        ]
        try await ref.collection("budgets").addDocument(data: data)
    }

    func fetchBudgets() async throws -> [Budget] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("budgets")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Budget.self) }
    }

    func deleteBudget(id: String) async throws {
        let ref = try userDoc()
        try await ref.collection("budgets").document(id).delete()
    }

    func updateBudgetSpent(id: String, spent: Double) async throws {
        let ref = try userDoc()
        try await ref.collection("budgets").document(id).updateData(["spent": spent])
    }

    // MARK: - Transactions

    func addTransaction(_ transaction: Transaction) async throws {
        let ref = try userDoc()
        var data: [String: Any] = [
            "amount": transaction.amount,
            "category": transaction.category,
            "note": transaction.note,
            "date": Timestamp(date: transaction.date),
            "isRecurring": transaction.isRecurring,
            "kind": transaction.kind.rawValue
        ]
        if let receiptURL = transaction.receiptURL {
            data["receiptURL"] = receiptURL
        }
        if let interval = transaction.recurrenceInterval {
            data["recurrenceInterval"] = interval.rawValue
        }
        if !transaction.tags.isEmpty {
            data["tags"] = transaction.tags
        }
        try await ref.collection("transactions").addDocument(data: data)
    }

    func fetchRecurringTransactions() async throws -> [Transaction] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("transactions")
            .whereField("isRecurring", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Transaction.self) }
    }

    func uploadReceipt(imageData: Data) async throws -> String {
        guard let uid else { throw ServiceError.notAuthenticated }
        let fileName = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("users/\(uid)/receipts/\(fileName)")
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }

    func deleteReceipt(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }

    func fetchTransactions() async throws -> [Transaction] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("transactions")
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Transaction.self) }
    }

    func deleteTransaction(id: String) async throws {
        let ref = try userDoc()
        try await ref.collection("transactions").document(id).delete()
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) async throws {
        let ref = try userDoc()
        let data: [String: Any] = [
            "title": goal.title,
            "emoji": goal.emoji,
            "targetAmount": goal.targetAmount,
            "currentAmount": goal.currentAmount,
            "deadline": Timestamp(date: goal.deadline)
        ]
        try await ref.collection("goals").addDocument(data: data)
    }

    func fetchGoals() async throws -> [Goal] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("goals")
            .order(by: "deadline")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Goal.self) }
    }

    func updateGoalProgress(id: String, currentAmount: Double) async throws {
        let ref = try userDoc()
        try await ref.collection("goals").document(id).updateData(["currentAmount": currentAmount])
    }

    func deleteGoal(id: String) async throws {
        let ref = try userDoc()
        try await ref.collection("goals").document(id).delete()
    }

    // MARK: - Documents

    func uploadDocument(data: Data, fileName: String, title: String) async throws -> UserDocument {
        guard let uid else { throw ServiceError.notAuthenticated }
        let storageRef = storage.reference().child("users/\(uid)/documents/\(fileName)")
        _ = try await storageRef.putDataAsync(data)
        let downloadURL = try await storageRef.downloadURL()

        let ref = try userDoc()
        let docData: [String: Any] = [
            "title": title,
            "fileName": fileName,
            "downloadURL": downloadURL.absoluteString,
            "uploadedAt": Timestamp()
        ]
        let docRef = try await ref.collection("documents").addDocument(data: docData)
        return UserDocument(id: docRef.documentID, title: title, fileName: fileName, downloadURL: downloadURL.absoluteString, uploadedAt: Date())
    }

    func fetchDocuments() async throws -> [UserDocument] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("documents")
            .order(by: "uploadedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: UserDocument.self) }
    }

    func deleteDocument(doc: UserDocument) async throws {
        guard let uid, let id = doc.id else { throw ServiceError.notAuthenticated }
        let storageRef = storage.reference().child("users/\(uid)/documents/\(doc.fileName)")
        try await storageRef.delete()
        let ref = try userDoc()
        try await ref.collection("documents").document(id).delete()
    }

    func listenToDocuments(onChange: @escaping ([UserDocument]) -> Void) throws -> ListenerRegistration {
        let ref = try userDoc()
        return ref.collection("documents")
            .order(by: "uploadedAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let documents = docs.compactMap { try? $0.data(as: UserDocument.self) }
                onChange(documents)
            }
    }

    // MARK: - Snapshot Listeners

    func listenToBudgets(onChange: @escaping ([Budget]) -> Void) throws -> ListenerRegistration {
        let ref = try userDoc()
        return ref.collection("budgets")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let budgets = docs.compactMap { try? $0.data(as: Budget.self) }
                onChange(budgets)
            }
    }

    func listenToTransactions(onChange: @escaping ([Transaction]) -> Void) throws -> ListenerRegistration {
        let ref = try userDoc()
        return ref.collection("transactions")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let txns = docs.compactMap { try? $0.data(as: Transaction.self) }
                onChange(txns)
            }
    }

    func listenToGoals(onChange: @escaping ([Goal]) -> Void) throws -> ListenerRegistration {
        let ref = try userDoc()
        return ref.collection("goals")
            .order(by: "deadline")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let goals = docs.compactMap { try? $0.data(as: Goal.self) }
                onChange(goals)
            }
    }

    // MARK: - Saved Opportunities

    func saveOpportunity(_ opportunity: Opportunity) async throws {
        let ref = try userDoc()
        let data: [String: Any] = [
            "title": opportunity.title,
            "employer": opportunity.employer,
            "descriptionText": opportunity.descriptionText,
            "location": opportunity.location,
            "type": opportunity.type.rawValue,
            "applyURL": opportunity.applyURL,
            "datePosted": Timestamp(date: opportunity.datePosted),
            "savedAt": Timestamp(),
            "externalId": opportunity.externalId
        ]
        try await ref.collection("savedOpportunities")
            .document(opportunity.externalId)
            .setData(data)
    }

    func fetchSavedOpportunities() async throws -> [Opportunity] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("savedOpportunities")
            .order(by: "savedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Opportunity.self) }
    }

    func unsaveOpportunity(id: String) async throws {
        let ref = try userDoc()
        try await ref.collection("savedOpportunities").document(id).delete()
    }

    func listenToSavedOpportunities(onChange: @escaping ([Opportunity]) -> Void) throws -> ListenerRegistration {
        let ref = try userDoc()
        return ref.collection("savedOpportunities")
            .order(by: "savedAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let opps = docs.compactMap { try? $0.data(as: Opportunity.self) }
                onChange(opps)
            }
    }

    // MARK: - Dismissed Opportunities

    func dismissOpportunity(id: String) async throws {
        let ref = try userDoc()
        try await ref.collection("dismissedOpportunities")
            .document(id)
            .setData(["dismissedAt": Timestamp()])
    }

    func fetchDismissedIds() async throws -> [String] {
        let ref = try userDoc()
        let snapshot = try await ref.collection("dismissedOpportunities").getDocuments()
        return snapshot.documents.map { $0.documentID }
    }

    func undismissOpportunity(id: String) async throws {
        let ref = try userDoc()
        try await ref.collection("dismissedOpportunities").document(id).delete()
    }

    // MARK: - Achievements

    func fetchAchievements() async throws -> AchievementData {
        let ref = try userDoc()
        let snapshot = try await ref.collection("meta").document("achievements").getDocument()
        guard snapshot.exists else { return AchievementData() }
        let data = snapshot.data() ?? [:]
        let streakDays = data["streakDays"] as? Int ?? 0
        let lastCheckIn = (data["lastCheckIn"] as? Timestamp)?.dateValue()
        var earnedBadges: [String: Date] = [:]
        if let badges = data["earnedBadges"] as? [String: Timestamp] {
            for (key, ts) in badges {
                earnedBadges[key] = ts.dateValue()
            }
        }
        return AchievementData(streakDays: streakDays, lastCheckIn: lastCheckIn, earnedBadges: earnedBadges)
    }

    func saveAchievements(_ achievements: AchievementData) async throws {
        let ref = try userDoc()
        var badgeTimestamps: [String: Timestamp] = [:]
        for (key, date) in achievements.earnedBadges {
            badgeTimestamps[key] = Timestamp(date: date)
        }
        var data: [String: Any] = [
            "streakDays": achievements.streakDays,
            "earnedBadges": badgeTimestamps
        ]
        if let lastCheckIn = achievements.lastCheckIn {
            data["lastCheckIn"] = Timestamp(date: lastCheckIn)
        }
        try await ref.collection("meta").document("achievements").setData(data, merge: true)
    }

    // MARK: - Error

    enum ServiceError: LocalizedError {
        case notAuthenticated
        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "You must be signed in."
            }
        }
    }
}
