import Foundation
import Observation
import FirebaseFirestore

@Observable
@MainActor
final class OpportunityViewModel {

    var cardStack: [Opportunity] = []
    var savedOpportunities: [Opportunity] = []
    var dismissedIds: Set<String> = []
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    var hasMorePages = true

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private let firestoreService = FirestoreService.shared

    @ObservationIgnored
    private let apiService = OpportunityService.shared

    @ObservationIgnored
    private var lastDismissed: Opportunity?

    var savedCount: Int { savedOpportunities.count }

    // MARK: - Lifecycle

    func startListening() {
        listener?.remove()
        do {
            listener = try firestoreService.listenToSavedOpportunities { [weak self] saved in
                Task { @MainActor in
                    self?.savedOpportunities = saved
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

    // MARK: - Fetch

    func fetchOpportunities(type: OpportunityType? = nil, reset: Bool = false) async {
        if reset {
            currentPage = 1
            hasMorePages = true
            cardStack = []
        }

        guard hasMorePages else { return }
        isLoading = true
        errorMessage = nil

        do {
            dismissedIds = Set(try await firestoreService.fetchDismissedIds())
            let savedIds = Set(savedOpportunities.map { $0.externalId })

            let results = try await apiService.fetchOpportunities(
                query: "student",
                type: type,
                page: currentPage
            )

            let filtered = results.filter { opp in
                !dismissedIds.contains(opp.externalId) && !savedIds.contains(opp.externalId)
            }

            if results.isEmpty {
                hasMorePages = false
            } else {
                cardStack.append(contentsOf: filtered)
                currentPage += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Swipe Actions

    func save(_ opportunity: Opportunity) async {
        cardStack.removeAll { $0.externalId == opportunity.externalId }
        lastDismissed = nil

        do {
            try await firestoreService.saveOpportunity(opportunity)
        } catch {
            errorMessage = error.localizedDescription
            cardStack.insert(opportunity, at: 0)
        }
    }

    func dismiss(_ opportunity: Opportunity) async {
        cardStack.removeAll { $0.externalId == opportunity.externalId }
        lastDismissed = opportunity
        dismissedIds.insert(opportunity.externalId)

        do {
            try await firestoreService.dismissOpportunity(id: opportunity.externalId)
        } catch {
            errorMessage = error.localizedDescription
            cardStack.insert(opportunity, at: 0)
            dismissedIds.remove(opportunity.externalId)
        }
    }

    func undoLastDismiss() async {
        guard let last = lastDismissed else { return }
        lastDismissed = nil
        dismissedIds.remove(last.externalId)
        cardStack.insert(last, at: 0)

        do {
            try await firestoreService.undismissOpportunity(id: last.externalId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var canUndo: Bool { lastDismissed != nil }

    // MARK: - Saved Management

    func unsave(_ opportunity: Opportunity) async {
        let eid = opportunity.externalId
        savedOpportunities.removeAll { $0.externalId == eid }

        do {
            try await firestoreService.unsaveOpportunity(id: eid)
        } catch {
            errorMessage = error.localizedDescription
            savedOpportunities.insert(opportunity, at: 0)
        }
    }

    // MARK: - Pagination

    func loadMoreIfNeeded(type: OpportunityType? = nil) async {
        if cardStack.count < 3 && hasMorePages && !isLoading {
            await fetchOpportunities(type: type)
        }
    }
}
