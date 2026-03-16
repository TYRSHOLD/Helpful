import Foundation

enum MoreDestination: String, Identifiable {
    case helpfulAI
    case documents
    case tools
    case discover
    case transactions
    case recurring
    case reminders

    var id: String { rawValue }
}

