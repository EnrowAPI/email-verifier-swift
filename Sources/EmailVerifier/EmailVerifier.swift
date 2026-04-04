import Foundation

// MARK: - Result types

public struct VerificationResult: Codable, Sendable {
    public let id: String
    public let email: String?
    public let qualification: String?
    public let status: String?
    public let message: String?
    public let creditsUsed: Int?

    enum CodingKeys: String, CodingKey {
        case id, email, qualification, status, message
        case creditsUsed = "credits_used"
    }
}

public struct BulkVerificationResult: Codable, Sendable {
    public let batchId: String
    public let total: Int
    public let status: String
    public let creditsUsed: Int?

    enum CodingKeys: String, CodingKey {
        case total, status
        case batchId = "batch_id"
        case creditsUsed = "credits_used"
    }
}

public struct BulkVerificationResults: Codable, Sendable {
    public let batchId: String
    public let status: String
    public let total: Int
    public let completed: Int?
    public let creditsUsed: Int?
    public let results: [VerificationResult]?

    enum CodingKeys: String, CodingKey {
        case status, total, completed, results
        case batchId = "batch_id"
        case creditsUsed = "credits_used"
    }
}

// MARK: - Bulk verification entry

public struct BulkVerification: Sendable {
    public let email: String
    public let custom: [String: String]?

    public init(
        email: String,
        custom: [String: String]? = nil
    ) {
        self.email = email
        self.custom = custom
    }
}

// MARK: - Error

public struct EmailVerifierError: Error, LocalizedError {
    public let statusCode: Int
    public let message: String

    public var errorDescription: String? { message }
}

// MARK: - EmailVerifier

public struct EmailVerifier: Sendable {
    private static let baseURL = "https://api.enrow.io"

    // MARK: - Single

    /// Start an email verification. Returns a verification ID you can poll with `getResult`.
    public static func verify(
        apiKey: String,
        email: String,
        webhook: String? = nil
    ) async throws -> VerificationResult {
        var body: [String: Any] = ["email": email]

        if let webhook {
            body["settings"] = ["webhook": webhook]
        }

        return try await post(apiKey: apiKey, path: "/email/verify/single", body: body)
    }

    /// Retrieve the result of a previous single verification by ID.
    public static func getResult(
        apiKey: String,
        id: String
    ) async throws -> VerificationResult {
        try await get(apiKey: apiKey, path: "/email/verify/single?id=\(id)")
    }

    // MARK: - Bulk

    /// Start a bulk email verification (up to 5,000 per batch).
    public static func verifyBulk(
        apiKey: String,
        verifications: [BulkVerification],
        webhook: String? = nil
    ) async throws -> BulkVerificationResult {
        let mapped: [[String: Any]] = verifications.map { v in
            var entry: [String: Any] = ["email": v.email]
            if let c = v.custom { entry["custom"] = c }
            return entry
        }

        var body: [String: Any] = ["verifications": mapped]

        if let webhook {
            body["settings"] = ["webhook": webhook]
        }

        return try await post(apiKey: apiKey, path: "/email/verify/bulk", body: body)
    }

    /// Retrieve the results of a previous bulk verification by batch ID.
    public static func getBulkResults(
        apiKey: String,
        id: String
    ) async throws -> BulkVerificationResults {
        try await get(apiKey: apiKey, path: "/email/verify/bulk?id=\(id)")
    }

    // MARK: - Networking

    private static func get<T: Decodable>(apiKey: String, path: String) async throws -> T {
        try await request(apiKey: apiKey, method: "GET", path: path, body: nil)
    }

    private static func post<T: Decodable>(apiKey: String, path: String, body: [String: Any]) async throws -> T {
        let data = try JSONSerialization.data(withJSONObject: body)
        return try await request(apiKey: apiKey, method: "POST", path: path, body: data)
    }

    private static func request<T: Decodable>(
        apiKey: String,
        method: String,
        path: String,
        body: Data?
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw EmailVerifierError(statusCode: 0, message: "Invalid URL: \(path)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw EmailVerifierError(statusCode: 0, message: "Invalid response")
        }

        if !(200...299).contains(http.statusCode) {
            let errorMessage: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String {
                errorMessage = msg
            } else {
                errorMessage = "API error \(http.statusCode)"
            }
            throw EmailVerifierError(statusCode: http.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
