import XCTest
@testable import App_IPinfo

final class IPLookupServiceTests: XCTestCase {

    var sut: IPLookupService!
    var mockSession: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        sut = IPLookupService(session: mockSession)
    }

    override func tearDown() {
        sut = nil
        mockSession = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Successful Lookup Tests

    func testLookupIPv4Success() async throws {
        let expectedIP = "8.8.8.8"
        let responseJSON = """
        {
            "ip": "\(expectedIP)",
            "city": "Mountain View",
            "region": "California",
            "country": "US",
            "country_name": "United States",
            "latitude": 37.386,
            "longitude": -122.0838,
            "asn": "AS15169",
            "org": "GOOGLE"
        }
        """

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains(expectedIP) ?? false)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        let result = try await sut.lookup(expectedIP)

        XCTAssertEqual(result.ip, expectedIP)
        XCTAssertEqual(result.city, "Mountain View")
        XCTAssertEqual(result.asn, "AS15169")
        XCTAssertEqual(result.org, "GOOGLE")
        XCTAssertNil(result.queriedDomain) // Direct IP lookup should not set queriedDomain
    }

    func testLookupIPv6Success() async throws {
        let expectedIP = "2001:4860:4860::8888"
        let responseJSON = """
        {
            "ip": "\(expectedIP)",
            "city": "Mountain View",
            "country_name": "United States"
        }
        """

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        let result = try await sut.lookup(expectedIP)
        XCTAssertEqual(result.ip, expectedIP)
    }

    // MARK: - Error Handling Tests

    func testLookupEmptyInputThrowsError() async {
        do {
            _ = try await sut.lookup("")
            XCTFail("Expected invalidInput error")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupWhitespaceInputThrowsError() async {
        do {
            _ = try await sut.lookup("   ")
            XCTFail("Expected invalidInput error")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupNewlinesOnlyThrowsError() async {
        do {
            _ = try await sut.lookup("\n\n\t")
            XCTFail("Expected invalidInput error")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupInputTooLongThrowsError() async {
        let longInput = String(repeating: "a", count: 300)
        do {
            _ = try await sut.lookup(longInput)
            XCTFail("Expected inputTooLong error")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("too long") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupAPIErrorResponse() async {
        let responseJSON = """
        {
            "ip": "8.8.8.8",
            "error": true,
            "reason": "Invalid IP address"
        }
        """

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected API error")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Invalid IP address")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected network error")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("connect") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupTimeoutError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected timeout error")
        } catch let error as IPLookupError {
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupServerError500() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected server error")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("unavailable") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupServerError503() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected server error")
        } catch let error as IPLookupError {
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupRateLimitError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected rate limit error")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("Too many") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupBadRequestError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected bad request error")
        } catch let error as IPLookupError {
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupInvalidJSON() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "invalid json".data(using: .utf8)!)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected decoding error")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("process") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupNullIPInResponse() async {
        let responseJSON = """
        {
            "ip": null,
            "error": false
        }
        """

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Expected error for null IP")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("resolve") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - My IP Tests

    func testLookupMyIPSuccess() async throws {
        let ipifyResponse = """
        {"ip": "203.45.67.89"}
        """

        let ipapiResponse = """
        {
            "ip": "203.45.67.89",
            "city": "Sydney",
            "region": "New South Wales",
            "country": "AU",
            "country_name": "Australia"
        }
        """

        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let urlString = request.url?.absoluteString ?? ""

            if urlString.contains("ipify.org") {
                // First request: get IPv4 from ipify
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, ipifyResponse.data(using: .utf8)!)
            } else {
                // Second request: lookup details from ipapi.co
                XCTAssertTrue(urlString.contains("203.45.67.89"), "Should lookup the IPv4 address")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, ipapiResponse.data(using: .utf8)!)
            }
        }

        let result = try await sut.lookupMyIP()

        XCTAssertEqual(requestCount, 2, "Should make two requests: ipify then ipapi")
        XCTAssertEqual(result.ip, "203.45.67.89")
        XCTAssertEqual(result.city, "Sydney")
        XCTAssertEqual(result.countryName, "Australia")
    }

    func testLookupMyIPReturnsIPv4() async throws {
        // This test verifies that lookupMyIP returns IPv4 address (not IPv6)
        let ipifyResponse = """
        {"ip": "1.2.3.4"}
        """

        let ipapiResponse = """
        {"ip": "1.2.3.4", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            if urlString.contains("ipify.org") {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, ipifyResponse.data(using: .utf8)!)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, ipapiResponse.data(using: .utf8)!)
            }
        }

        let result = try await sut.lookupMyIP()

        // Verify it's a valid IPv4 address
        XCTAssertTrue(IPLookupService.isValidIPv4(result.ip ?? ""), "Should return IPv4 address")
        XCTAssertFalse(IPLookupService.isValidIPv6(result.ip ?? ""), "Should not return IPv6 address")
    }

    func testLookupMyIPFailsWhenIpifyFails() async {
        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            if urlString.contains("ipify.org") {
                // ipify returns error
                let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            } else {
                XCTFail("Should not reach ipapi if ipify fails")
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }
        }

        do {
            _ = try await sut.lookupMyIP()
            XCTFail("Expected error when ipify fails")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Input Sanitization Tests

    func testLookupTrimsWhitespace() async throws {
        let responseJSON = """
        {"ip": "8.8.8.8", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("8.8.8.8") ?? false)
            XCTAssertFalse(request.url?.absoluteString.contains("%20") ?? true) // No encoded spaces
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("  8.8.8.8  ")
    }

    func testLookupStripsHttpsPrefix() async throws {
        let responseJSON = """
        {"ip": "142.250.185.46", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            // Should not contain the user's https:// prefix in the path - only ipapi.co's https
            XCTAssertFalse(urlString.contains("https://google"))
            XCTAssertFalse(urlString.contains("http://google"))
            // Verify it's using ipapi.co
            XCTAssertTrue(urlString.hasPrefix("https://ipapi.co/"))
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("https://google.com")
    }

    func testLookupStripsHttpPrefix() async throws {
        let responseJSON = """
        {"ip": "142.250.185.46", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            XCTAssertFalse(urlString.contains("http://example"))
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("http://example.com")
    }

    func testLookupStripsWwwPrefix() async throws {
        let responseJSON = """
        {"ip": "142.250.185.46", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            XCTAssertFalse(urlString.contains("www."))
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("www.google.com")
    }

    func testLookupStripsPath() async throws {
        let responseJSON = """
        {"ip": "142.250.185.46", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            XCTAssertFalse(urlString.contains("/search"))
            XCTAssertFalse(urlString.contains("path"))
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("https://www.google.com/search?q=test")
    }

    func testLookupInvalidCharactersThrowsError() async {
        do {
            _ = try await sut.lookup("8.8.8.8<script>")
            XCTFail("Expected invalidInput error")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLookupPathTraversalThrowsError() async {
        do {
            _ = try await sut.lookup("../../../etc/passwd")
            XCTFail("Expected invalidInput error")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - IPv4 Validation Tests

    func testIsValidIPv4WithValidIP() {
        XCTAssertTrue(IPLookupService.isValidIPv4("8.8.8.8"))
        XCTAssertTrue(IPLookupService.isValidIPv4("192.168.1.1"))
        XCTAssertTrue(IPLookupService.isValidIPv4("0.0.0.0"))
        XCTAssertTrue(IPLookupService.isValidIPv4("255.255.255.255"))
        XCTAssertTrue(IPLookupService.isValidIPv4("10.0.0.1"))
    }

    func testIsValidIPv4WithInvalidIP() {
        XCTAssertFalse(IPLookupService.isValidIPv4("256.1.1.1"))
        XCTAssertFalse(IPLookupService.isValidIPv4("1.2.3"))
        XCTAssertFalse(IPLookupService.isValidIPv4("1.2.3.4.5"))
        XCTAssertFalse(IPLookupService.isValidIPv4(""))
        XCTAssertFalse(IPLookupService.isValidIPv4("google.com"))
        XCTAssertFalse(IPLookupService.isValidIPv4("1.2.3."))
        XCTAssertFalse(IPLookupService.isValidIPv4(".1.2.3"))
        XCTAssertFalse(IPLookupService.isValidIPv4("01.02.03.04")) // Leading zeros
        XCTAssertFalse(IPLookupService.isValidIPv4("-1.2.3.4"))
    }

    // MARK: - IPv6 Validation Tests

    func testIsValidIPv6WithValidIP() {
        XCTAssertTrue(IPLookupService.isValidIPv6("2001:4860:4860::8888"))
        XCTAssertTrue(IPLookupService.isValidIPv6("::1"))
        XCTAssertTrue(IPLookupService.isValidIPv6("fe80::1"))
        XCTAssertTrue(IPLookupService.isValidIPv6("2001:db8:85a3::8a2e:370:7334"))
    }

    func testIsValidIPv6WithInvalidIP() {
        XCTAssertFalse(IPLookupService.isValidIPv6("8.8.8.8"))
        XCTAssertFalse(IPLookupService.isValidIPv6("google.com"))
        XCTAssertFalse(IPLookupService.isValidIPv6(""))
        XCTAssertFalse(IPLookupService.isValidIPv6("2001:4860:4860:8888:8888:8888:8888:8888:8888")) // Too many groups
    }

    // MARK: - Domain Validation Tests

    func testIsValidDomainWithValidDomain() {
        XCTAssertTrue(IPLookupService.isValidDomain("google.com"))
        XCTAssertTrue(IPLookupService.isValidDomain("sub.domain.example.com"))
        XCTAssertTrue(IPLookupService.isValidDomain("example.co.uk"))
        XCTAssertTrue(IPLookupService.isValidDomain("test-domain.com"))
    }

    func testIsValidDomainWithInvalidDomain() {
        XCTAssertFalse(IPLookupService.isValidDomain(""))
        XCTAssertFalse(IPLookupService.isValidDomain("localhost"))
        XCTAssertFalse(IPLookupService.isValidDomain("-invalid.com"))
        XCTAssertFalse(IPLookupService.isValidDomain("invalid-.com"))
    }

    // MARK: - Request Configuration Tests

    func testRequestHasCorrectHeaders() async throws {
        let responseJSON = """
        {"ip": "8.8.8.8", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "App_IPinfo/1.0")
            XCTAssertEqual(request.httpMethod, "GET")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("8.8.8.8")
    }

    func testRequestHasReasonableTimeout() async throws {
        let responseJSON = """
        {"ip": "8.8.8.8", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            XCTAssertLessThanOrEqual(request.timeoutInterval, 30)
            XCTAssertGreaterThan(request.timeoutInterval, 0)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("8.8.8.8")
    }

    func testRequestUsesHTTPS() async throws {
        let responseJSON = """
        {"ip": "8.8.8.8", "city": "Test"}
        """

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.scheme, "https")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }

        _ = try await sut.lookup("8.8.8.8")
    }

    // MARK: - Error Message Tests

    func testAllErrorsHaveDescriptions() {
        let errors: [IPLookupError] = [
            .invalidInput,
            .inputTooLong,
            .invalidURL,
            .networkError(URLError(.notConnectedToInternet)),
            .decodingError(NSError(domain: "test", code: 0)),
            .apiError("Test error"),
            .rateLimited,
            .serverError(500),
            .dnsResolutionFailed("test.com")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error \(error) should have non-empty description")
        }
    }

    func testDNSResolutionFailedErrorContainsDomain() {
        let error = IPLookupError.dnsResolutionFailed("example.com")
        XCTAssertTrue(error.errorDescription?.contains("example.com") ?? false)
    }
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Request handler not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
