import Foundation
import FirebaseAI
import FirebaseAILogic

@MainActor
final class AIService {

    static let shared = AIService()

    private let model: GenerativeModel

    private init() {
        let firebaseAI = FirebaseAI.firebaseAI()
        // Gemini 2.5 Flash is a fast, cost‑effective production model for this use case.
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 40
        )
        self.model = firebaseAI.generativeModel(
            modelName: "gemini-2.5-flash",
            generationConfig: config
        )
    }

    struct FinancialContext {
        var userName: String
        var school: String
        var major: String

        var currentBudgetTotal: Double
        var currentBudgetSpent: Double

        var topCategorySummary: String
        var goalsSummary: String
        var netIncomeSummary: String
    }

    struct AIMessage {
        enum Role {
            case user
            case assistant
        }

        var role: Role
        var content: String
    }

    // MARK: - Public Chat API

    func sendChat(
        messages: [AIMessage],
        context: FinancialContext?
    ) async throws -> String {
        let prompt = buildChatPrompt(messages: messages, context: context)
        let safePrompt = Self.truncateIfNeeded(prompt)
        let response = try await model.generateContent(safePrompt)
        return response.text ?? ""
    }

    // MARK: - Insights API

    func generateInsights(
        contextDescription: String
    ) async throws -> [AIInsight] {
        let prompt = """
        You are Helpful AI, a friendly financial assistant for people getting started with their finances.

        Below is a snapshot of the user's finances:

        \(contextDescription)

        Based on this, generate 1 to 4 short, actionable insights.
        Return ONLY a JSON array, with no extra text, where each element has:
        {
          "icon": "sf-symbol-name",
          "title": "Short title",
          "body": "1-2 sentence helpful explanation.",
          "category": "warning" | "tip" | "celebration"
        }
        Make sure the JSON is valid and has double quotes around all keys and string values.
        """

        let safePrompt = Self.truncateIfNeeded(prompt)
        let response = try await model.generateContent(safePrompt)
        let raw = response.text ?? ""
        let cleaned = Self.stripJSON(from: raw)
        let data = Data(cleaned.utf8)
        let decoder = JSONDecoder()
        return (try? decoder.decode([AIInsight].self, from: data)) ?? []
    }

    func generateSummary(
        contextDescription: String
    ) async throws -> String {
        let prompt = """
        You are Helpful AI, a friendly financial assistant for people getting started with their finances.

        Here is a snapshot of the user's finances:

        \(contextDescription)

        Write a concise 2-3 sentence summary of their current financial health.
        Use plain language and be supportive.
        """

        let safePrompt = Self.truncateIfNeeded(prompt)
        let response = try await model.generateContent(safePrompt)
        return response.text ?? ""
    }

    // MARK: - Prompt Builders

    private func buildChatPrompt(
        messages: [AIMessage],
        context: FinancialContext?
    ) -> String {
        var lines: [String] = []

        lines.append("""
        You are Helpful AI, a friendly financial assistant for people getting started with their finances.
        Speak clearly, avoid jargon, and keep answers concise but supportive.
        Never give investment advice or recommend specific securities.
        Focus on budgeting, saving, understanding spending, and simple ways to increase income or reduce expenses.
        """)

        if let context {
            let remaining = max(context.currentBudgetTotal - context.currentBudgetSpent, 0)
            lines.append("""

            User profile:
            - Name: \(context.userName)
            - School: \(context.school.isEmpty ? "Not provided" : context.school)
            - Major: \(context.major.isEmpty ? "Not provided" : context.major)

            Current month budget:
            - Total: \(currencyString(context.currentBudgetTotal))
            - Spent: \(currencyString(context.currentBudgetSpent))
            - Remaining: \(currencyString(remaining))

            Top categories: \(context.topCategorySummary)
            Goals: \(context.goalsSummary)
            Net income: \(context.netIncomeSummary)
            """)
        }

        lines.append("\nConversation so far:")
        for message in messages {
            let prefix: String
            switch message.role {
            case .user: prefix = "User"
            case .assistant: prefix = "Helper"
            }
            lines.append("\(prefix): \(message.content)")
        }

        lines.append("""

        When you respond, talk directly to the user.
        If you reference numbers, prefer the ones from the context above.
        
        If the user explicitly asks you to help set up a savings goal or monthly budget, or clearly agrees to one of your suggestions, then in addition to your normal conversational answer you MUST append a final line starting with:
        ACTIONS_JSON:
        followed by a single-line JSON array describing one or more actions to take.
        
        Each action object should have:
        - "type": "create_goal" or "create_budget"
        - For "create_goal": "title" (String), "target" (Number), "monthsFromNow" (Int, how many whole months from now the deadline should be)
        - For "create_budget": "month" (String, month name like "March"), "total" (Number)
        
        Example:
        ACTIONS_JSON: [{"type":"create_goal","title":"New laptop","target":800,"monthsFromNow":6},{"type":"create_budget","month":"April","total":500}]

        If no concrete goal or budget should be created, do not output ACTIONS_JSON at all.
        """)

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    /// Provide a user-friendly description of Firebase AI generateContent errors,
    /// while logging detailed diagnostics to the console for debugging.
    static func formatGenerateContentError(_ error: Error) -> String {
        if let genError = error as? FirebaseAILogic.GenerateContentError {
            switch genError {
            case let .internalError(underlying):
                let nsError = underlying as NSError
                print("FirebaseAI internalError:", nsError.domain, nsError.code, nsError.userInfo)
                return "AI request failed due to an internal error. Please try again in a moment."

            case let .promptImageContentError(underlying):
                let nsError = underlying as NSError
                print("FirebaseAI promptImageContentError:", nsError.domain, nsError.code, nsError.userInfo)
                return "We couldn't understand this AI request. Try rephrasing or simplifying your question."

            case let .promptBlocked(response):
                let reasonDescription = String(describing: response.promptFeedback?.blockReason)
                print("FirebaseAI promptBlocked. Reason:", reasonDescription, "Full response:", response)
                return "Your question was blocked by safety filters. Try asking it in a different way."

            case let .responseStoppedEarly(reason, response):
                print("FirebaseAI responseStoppedEarly. Reason:", reason, "Response:", response)
                return "The AI response stopped early. Please try asking again."
            }
        }

        let nsError = error as NSError
        print("FirebaseAI unknown generateContent error:", nsError.domain, nsError.code, nsError.userInfo)
        return "AI request failed (\(nsError.code)). Please try again."
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private static func truncateIfNeeded(_ text: String, limit: Int = 8000) -> String {
        guard text.count > limit else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: limit)
        return String(text[..<endIndex])
    }

    private static func stripJSON(from text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            // Remove Markdown code fences if present.
            if let firstFenceRange = result.range(of: "```") {
                result.removeSubrange(firstFenceRange)
            }
            if let lastFenceRange = result.range(of: "```", options: .backwards) {
                result.removeSubrange(lastFenceRange)
            }
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }
}

