import Foundation

@MainActor
final class OpportunityService {

    static let shared = OpportunityService()
    private let session = URLSession.shared
    private let host = "jsearch.p.rapidapi.com"

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["RapidAPIKey"] as? String,
              key != "YOUR_RAPIDAPI_KEY_HERE"
        else { return "" }
        return key
    }

    private init() {}

    // MARK: - Public

    func fetchOpportunities(
        query: String,
        type: OpportunityType?,
        page: Int = 1,
        perPage: Int = 10
    ) async throws -> [Opportunity] {
        let searchQuery: String
        switch type {
        case .internship:
            searchQuery = "\(query) internship"
        case .scholarship:
            searchQuery = "\(query) scholarship"
        case nil:
            searchQuery = "\(query) internship OR scholarship"
        }

        guard !apiKey.isEmpty else { throw OpportunityAPIError.missingAPIKey }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "query", value: searchQuery),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "num_pages", value: "1"),
            URLQueryItem(name: "date_posted", value: "month")
        ]

        guard let url = components.url else { throw OpportunityAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpportunityAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200: break
        case 429: throw OpportunityAPIError.rateLimited
        case 401, 403: throw OpportunityAPIError.unauthorized
        default: throw OpportunityAPIError.serverError(httpResponse.statusCode)
        }

        return try parseResponse(data: data, forType: type)
    }

    // MARK: - Parsing

    private func parseResponse(data: Data, forType type: OpportunityType?) throws -> [Opportunity] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]]
        else { return [] }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()

        return dataArray.compactMap { job -> Opportunity? in
            guard let jobId = job["job_id"] as? String,
                  let title = job["job_title"] as? String,
                  let employer = job["employer_name"] as? String
            else { return nil }

            let description = job["job_description"] as? String ?? ""
            let city = job["job_city"] as? String ?? ""
            let state = job["job_state"] as? String ?? ""
            let isRemote = job["job_is_remote"] as? Bool ?? false
            let applyLink = job["job_apply_link"] as? String ?? ""

            let location: String
            if isRemote {
                location = "Remote"
            } else if !city.isEmpty && !state.isEmpty {
                location = "\(city), \(state)"
            } else if !city.isEmpty {
                location = city
            } else if !state.isEmpty {
                location = state
            } else {
                location = "Not specified"
            }

            var postedDate = Date()
            if let dateString = job["job_posted_at_datetime_utc"] as? String {
                postedDate = dateFormatter.date(from: dateString)
                    ?? fallbackFormatter.date(from: dateString)
                    ?? Date()
            }

            let inferredType = inferType(title: title, description: description, requestedType: type)

            let trimmedDescription = String(description.prefix(500))

            return Opportunity(
                title: title,
                employer: employer,
                descriptionText: trimmedDescription,
                location: location,
                type: inferredType,
                applyURL: applyLink,
                datePosted: postedDate,
                externalId: jobId
            )
        }
    }

    private func inferType(title: String, description: String, requestedType: OpportunityType?) -> OpportunityType {
        if let requestedType { return requestedType }

        let combined = (title + " " + description).lowercased()
        if combined.contains("scholarship") || combined.contains("grant") || combined.contains("fellowship") || combined.contains("financial aid") {
            return .scholarship
        }
        return .internship
    }

    // MARK: - Errors

    enum OpportunityAPIError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case invalidResponse
        case rateLimited
        case unauthorized
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "API key not configured. Add your RapidAPI key to Secrets.plist."
            case .invalidURL:
                return "Failed to build request URL."
            case .invalidResponse:
                return "Received an invalid response from the server."
            case .rateLimited:
                return "API rate limit reached. Try again later."
            case .unauthorized:
                return "Invalid API key. Check your RapidAPI subscription."
            case .serverError(let code):
                return "Server error (\(code)). Try again later."
            }
        }
    }
}
