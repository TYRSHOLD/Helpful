import Foundation
import Observation

@Observable
@MainActor
final class AIViewModel {

    struct ChatMessage: Identifiable, Equatable, Codable {
        enum Role: String, Codable {
            case user
            case assistant
        }

        let id: UUID
        let role: Role
        let content: String
        var displayedContent: String?
        let timestamp: Date

        init(
            id: UUID = UUID(),
            role: Role,
            content: String,
            displayedContent: String? = nil,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.role = role
            self.content = content
            self.displayedContent = displayedContent
            self.timestamp = timestamp
        }
    }

    struct ChatAction: Identifiable, Equatable {
        enum Kind {
            case createGoal
            case createBudget
        }

        let id = UUID()
        let kind: Kind
        let title: String
        let amount: Double
        let monthsFromNow: Int?
        let month: String?
    }

    private struct ActionPayload: Codable {
        let type: String
        let title: String?
        let target: Double?
        let monthsFromNow: Int?
        let month: String?
        let total: Double?
    }

    private let storageKey = "AIChatMessages"

    var messages: [ChatMessage] = [] {
        didSet { persistMessages() }
    }
    var isSending = false
    var errorMessage: String?

    // Tracks whether an assistant message is currently animating.
    var animatingMessageID: UUID?

    private let service = AIService.shared
    var pendingActions: [ChatAction] = []

    init() {
        loadMessages()
    }

    func send(
        text: String,
        context: AIService.FinancialContext?
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(
            ChatMessage(role: .user, content: trimmed, displayedContent: nil, timestamp: Date())
        )

        isSending = true
        errorMessage = nil

        do {
            let history = messages.map { msg in
                AIService.AIMessage(
                    role: msg.role == .user ? .user : .assistant,
                    content: msg.content
                )
            }
            let reply = try await service.sendChat(messages: history, context: context)
            let (cleanText, actions) = Self.extractActions(from: reply)
            messages.append(
                ChatMessage(role: .assistant, content: cleanText, displayedContent: "", timestamp: Date())
            )
            animatingMessageID = messages.last?.id
            if !actions.isEmpty {
                pendingActions.append(contentsOf: actions)
            }
        } catch {
            errorMessage = AIService.formatGenerateContentError(error)
        }

        isSending = false
    }

    // MARK: - Persistence

    private func persistMessages() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to persist AI chat messages:", error)
        }
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoder = JSONDecoder()
            var decoded = try decoder.decode([ChatMessage].self, from: data)
            for index in decoded.indices {
                decoded[index].displayedContent = decoded[index].content
            }
            messages = decoded
        } catch {
            print("Failed to load AI chat messages:", error)
        }
    }

    // MARK: - Action Parsing

    private static func extractActions(from reply: String) -> (String, [ChatAction]) {
        let marker = "ACTIONS_JSON:"
        guard let range = reply.range(of: marker) else {
            return (reply, [])
        }

        let visibleText = String(reply[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonPart = reply[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonPart.data(using: .utf8) else {
            return (visibleText, [])
        }

        do {
            let payloads = try JSONDecoder().decode([ActionPayload].self, from: data)
            let actions: [ChatAction] = payloads.compactMap { payload in
                switch payload.type {
                case "create_goal":
                    guard let title = payload.title,
                          let target = payload.target else { return nil }
                    return ChatAction(
                        kind: .createGoal,
                        title: title,
                        amount: target,
                        monthsFromNow: payload.monthsFromNow ?? 6,
                        month: nil
                    )
                case "create_budget":
                    guard let month = payload.month,
                          let total = payload.total else { return nil }
                    return ChatAction(
                        kind: .createBudget,
                        title: "Budget for \(month)",
                        amount: total,
                        monthsFromNow: nil,
                        month: month
                    )
                default:
                    return nil
                }
            }
            return (visibleText, actions)
        } catch {
            print("Failed to parse ACTIONS_JSON:", error)
            return (visibleText, [])
        }
    }
}

