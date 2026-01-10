import Foundation

enum IPLookupError: LocalizedError {
    case invalidInput
    case inputTooLong
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case rateLimited
    case serverError(Int)
    case dnsResolutionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please enter a valid IP address or domain name"
        case .inputTooLong:
            return "Input is too long. Please enter a valid IP or domain."
        case .invalidURL:
            return "Unable to process the request"
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .decodingError:
            return "Unable to process the server response"
        case .apiError(let message):
            return message
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError:
            return "Server is temporarily unavailable. Please try again."
        case .dnsResolutionFailed(let domain):
            return "Could not resolve domain: \(domain)"
        }
    }
}

actor IPLookupService {
    private let baseURL = "https://ipapi.co"
    private let session: URLSession
    private let maxInputLength = 253 // Max domain name length per RFC
    private let requestTimeout: TimeInterval = 15
    private let maxResponseSize = 1024 * 100 // 100KB max response

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(_ query: String) async throws -> IPInfo {
        let sanitizedQuery = try sanitizeInput(query)

        // Check if it's already an IP address
        let ipToLookup: String
        let originalDomain: String?

        if Self.isValidIPv4(sanitizedQuery) || Self.isValidIPv6(sanitizedQuery) {
            ipToLookup = sanitizedQuery
            originalDomain = nil
        } else {
            // It's a domain name, resolve it to an IP address first
            originalDomain = sanitizedQuery
            ipToLookup = try await resolveDomain(sanitizedQuery)
        }

        guard let url = buildURL(for: ipToLookup) else {
            throw IPLookupError.invalidURL
        }

        var result = try await performRequest(url: url)

        // Store the original domain if it was a domain lookup
        if let domain = originalDomain {
            result.queriedDomain = domain
        }

        return result
    }

    private func resolveDomain(_ domain: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var hints = addrinfo()
                hints.ai_family = AF_UNSPEC  // Allow IPv4 or IPv6
                hints.ai_socktype = SOCK_STREAM

                var result: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(domain, nil, &hints, &result)

                defer {
                    if result != nil {
                        freeaddrinfo(result)
                    }
                }

                guard status == 0, let addrInfo = result else {
                    continuation.resume(throwing: IPLookupError.dnsResolutionFailed(domain))
                    return
                }

                // Get the first IP address
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

                let sockaddrPtr = addrInfo.pointee.ai_addr
                let sockaddrLen = addrInfo.pointee.ai_addrlen

                let niStatus = getnameinfo(
                    sockaddrPtr,
                    sockaddrLen,
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )

                guard niStatus == 0 else {
                    continuation.resume(throwing: IPLookupError.dnsResolutionFailed(domain))
                    return
                }

                let ipAddress = String(cString: hostname)
                continuation.resume(returning: ipAddress)
            }
        }
    }

    func lookupMyIP() async throws -> IPInfo {
        // First, get IPv4 address from ipify (which guarantees IPv4)
        let ipv4Address = try await getMyIPv4Address()

        // Then look up the details using ipapi.co
        guard let url = buildURL(for: ipv4Address) else {
            throw IPLookupError.invalidURL
        }

        return try await performRequest(url: url)
    }

    private func getMyIPv4Address() async throws -> String {
        guard let url = URL(string: "https://api.ipify.org?format=json") else {
            throw IPLookupError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = requestTimeout

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw IPLookupError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IPLookupError.networkError(URLError(.badServerResponse))
        }

        // Parse the simple JSON response: {"ip":"x.x.x.x"}
        struct IPResponse: Decodable {
            let ip: String
        }

        do {
            let ipResponse = try JSONDecoder().decode(IPResponse.self, from: data)
            return ipResponse.ip
        } catch {
            throw IPLookupError.decodingError(error)
        }
    }

    // MARK: - Private Methods

    private func sanitizeInput(_ input: String) throws -> String {
        // Trim whitespace and newlines
        var trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for empty input
        guard !trimmed.isEmpty else {
            throw IPLookupError.invalidInput
        }

        // Remove URL prefixes (http://, https://)
        if trimmed.lowercased().hasPrefix("https://") {
            trimmed = String(trimmed.dropFirst(8))
        } else if trimmed.lowercased().hasPrefix("http://") {
            trimmed = String(trimmed.dropFirst(7))
        }

        // Remove www. prefix for domain lookups
        if trimmed.lowercased().hasPrefix("www.") {
            trimmed = String(trimmed.dropFirst(4))
        }

        // Remove trailing slashes and paths
        if let slashIndex = trimmed.firstIndex(of: "/") {
            trimmed = String(trimmed[..<slashIndex])
        }

        // Check input length to prevent DoS
        guard trimmed.count <= maxInputLength else {
            throw IPLookupError.inputTooLong
        }

        // Remove any null bytes (security measure)
        let sanitized = trimmed.replacingOccurrences(of: "\0", with: "")

        // Basic validation - only allow valid characters for IP/domain
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: ".-:"))

        guard sanitized.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw IPLookupError.invalidInput
        }

        // Prevent path traversal attempts
        guard !sanitized.contains("..") else {
            throw IPLookupError.invalidInput
        }

        return sanitized
    }

    private func buildURL(for query: String) -> URL? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: "\(baseURL)/\(encodedQuery)/json/")
    }

    private func performRequest(url: URL) async throws -> IPInfo {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("App_IPinfo/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = requestTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw IPLookupError.networkError(urlError)
            case .notConnectedToInternet, .networkConnectionLost:
                throw IPLookupError.networkError(urlError)
            default:
                throw IPLookupError.networkError(urlError)
            }
        } catch {
            throw IPLookupError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IPLookupError.networkError(URLError(.badServerResponse))
        }

        // Check response size to prevent memory issues
        guard data.count <= maxResponseSize else {
            throw IPLookupError.decodingError(NSError(domain: "IPLookup", code: -1))
        }

        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            break // Success
        case 429:
            throw IPLookupError.rateLimited
        case 400...499:
            throw IPLookupError.apiError("Invalid request")
        case 500...599:
            throw IPLookupError.serverError(httpResponse.statusCode)
        default:
            throw IPLookupError.serverError(httpResponse.statusCode)
        }

        return try decodeResponse(data)
    }

    private func decodeResponse(_ data: Data) throws -> IPInfo {
        let decoder = JSONDecoder()

        do {
            let ipInfo = try decoder.decode(IPInfo.self, from: data)

            // Check for API-level errors
            if ipInfo.error == true {
                let reason = ipInfo.reason ?? "Unknown error"
                throw IPLookupError.apiError(reason)
            }

            // Check if IP was resolved
            guard ipInfo.ip != nil else {
                throw IPLookupError.apiError("Could not resolve IP address for this domain")
            }

            return ipInfo
        } catch let error as IPLookupError {
            throw error
        } catch {
            throw IPLookupError.decodingError(error)
        }
    }
}

// MARK: - Input Validation Helpers

extension IPLookupService {
    static func isValidIPv4(_ string: String) -> Bool {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return false }

        return parts.allSatisfy { part in
            guard let number = Int(part), (0...255).contains(number) else {
                return false
            }
            // Prevent leading zeros (except for "0" itself)
            if part.count > 1 && part.first == "0" {
                return false
            }
            return true
        }
    }

    static func isValidIPv6(_ string: String) -> Bool {
        // Basic IPv6 validation
        // Empty string is not valid
        guard !string.isEmpty else { return false }

        // IPv6 must contain at least one colon
        guard string.contains(":") else { return false }

        let parts = string.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count >= 2 && parts.count <= 8 else { return false }

        return parts.allSatisfy { part in
            part.isEmpty || (part.count <= 4 && part.allSatisfy { $0.isHexDigit })
        }
    }

    static func isValidDomain(_ string: String) -> Bool {
        // Basic domain validation
        let domainRegex = #"^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#
        return string.range(of: domainRegex, options: .regularExpression) != nil
    }
}
