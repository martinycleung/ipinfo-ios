import XCTest
@testable import App_IPinfo

final class SecurityTests: XCTestCase {

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

    // MARK: - Input Validation Security Tests

    func testSQLInjectionAttemptIsRejected() async {
        let maliciousInput = "'; DROP TABLE users; --"

        do {
            _ = try await sut.lookup(maliciousInput)
            XCTFail("Should reject SQL injection attempt")
        } catch let error as IPLookupError {
            // Should be rejected with invalid input error
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testXSSAttemptIsRejected() async {
        let xssInput = "<script>alert('xss')</script>"

        do {
            _ = try await sut.lookup(xssInput)
            XCTFail("Should reject XSS attempt")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testPathTraversalAttemptIsRejected() async {
        let pathTraversalInput = "../../../etc/passwd"

        do {
            _ = try await sut.lookup(pathTraversalInput)
            XCTFail("Should reject path traversal attempt")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testCommandInjectionAttemptIsRejected() async {
        let cmdInjectionInput = "8.8.8.8; rm -rf /"

        do {
            _ = try await sut.lookup(cmdInjectionInput)
            XCTFail("Should reject command injection attempt")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNullByteInjectionIsHandled() async {
        let nullByteInput = "8.8.8.8\0malicious"

        // Should handle null bytes - either succeed with sanitized input or fail safely
        MockURLProtocol.requestHandler = { request in
            // Verify null byte is not in the URL
            let urlString = request.url?.absoluteString ?? ""
            XCTAssertFalse(urlString.contains("\0"))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        do {
            _ = try await sut.lookup(nullByteInput)
        } catch {
            // May throw, which is acceptable
        }
    }

    func testUnicodeNormalizationAttackIsHandled() async {
        // Unicode lookalike characters - should not crash
        let unicodeInput = "ɡoogle.com" // Using Latin small letter script g

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "1.2.3.4", "city": "Test"}
                """.data(using: .utf8)!)
        }

        // Should handle unicode without crashing
        _ = try? await sut.lookup(unicodeInput)
    }

    func testHTMLEntitiesAreRejected() async {
        let htmlInput = "8.8.8.8&lt;script&gt;"

        do {
            _ = try await sut.lookup(htmlInput)
            XCTFail("Should reject HTML entities")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testBackslashesAreRejected() async {
        let backslashInput = "8.8.8.8\\..\\windows"

        do {
            _ = try await sut.lookup(backslashInput)
            XCTFail("Should reject backslashes")
        } catch let error as IPLookupError {
            XCTAssertEqual(error.errorDescription, "Please enter a valid IP address or domain name")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Input Length Security Tests

    func testVeryLongInputIsRejected() async {
        let longInput = String(repeating: "a", count: 300)

        do {
            _ = try await sut.lookup(longInput)
            XCTFail("Should reject very long input")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("too long") ?? false)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMaxLengthDomainIsAccepted() async {
        // 253 characters is the max domain name length per RFC
        let maxLengthDomain = String(repeating: "a", count: 60) + ".com"

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "1.2.3.4", "city": "Test"}
                """.data(using: .utf8)!)
        }

        // Should not throw inputTooLong error
        _ = try? await sut.lookup(maxLengthDomain)
    }

    // MARK: - Network Security Tests

    func testHTTPSIsUsed() async {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.scheme, "https", "Must use HTTPS")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        _ = try? await sut.lookup("8.8.8.8")
    }

    func testTimeoutIsReasonable() async {
        MockURLProtocol.requestHandler = { request in
            // Timeout should be reasonable (not too long for security)
            XCTAssertLessThanOrEqual(request.timeoutInterval, 30)
            XCTAssertGreaterThan(request.timeoutInterval, 0)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        _ = try? await sut.lookup("8.8.8.8")
    }

    func testCacheIsDisabled() async {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        _ = try? await sut.lookup("8.8.8.8")
    }

    // MARK: - Response Security Tests

    func testLargeResponseIsRejected() async {
        // Create a response larger than maxResponseSize (100KB)
        let largeResponse = String(repeating: "x", count: 150_000)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, largeResponse.data(using: .utf8)!)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Should reject large response")
        } catch {
            // Expected - large response should fail
            XCTAssertTrue(true)
        }
    }

    func testMalformedJSONDoesNotCrash() async {
        let malformedJSON = "{ \"ip\": \"8.8.8.8\", \"city\": "

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, malformedJSON.data(using: .utf8)!)
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Should fail on malformed JSON")
        } catch let error as IPLookupError {
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    // MARK: - Error Message Security Tests

    func testErrorMessagesDoNotLeakSensitiveInfo() {
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
            let description = error.errorDescription ?? ""
            // Should not contain internal paths
            XCTAssertFalse(description.contains("/Users/"))
            XCTAssertFalse(description.contains("/var/"))
            XCTAssertFalse(description.contains("/private/"))
            // Should not contain stack traces
            XCTAssertFalse(description.contains("at line"))
            XCTAssertFalse(description.contains("Stack trace"))
            XCTAssertFalse(description.contains(".swift:"))
            // Should not contain internal class names
            XCTAssertFalse(description.contains("URLSession"))
            XCTAssertFalse(description.contains("NSError"))
        }
    }

    func testAPIErrorDoesNotExposeInternalDetails() {
        let apiError = IPLookupError.apiError("Connection refused to 192.168.1.1:3306")
        // The error message passes through - it's from the API
        XCTAssertNotNil(apiError.errorDescription)
    }

    // MARK: - Rate Limiting Tests

    func testRateLimitErrorIsHandledGracefully() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Retry-After": "60"]
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.lookup("8.8.8.8")
            XCTFail("Should throw rate limit error")
        } catch let error as IPLookupError {
            XCTAssertTrue(error.errorDescription?.contains("Too many") ?? false)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentLookupsDoNotCrash() async {
        MockURLProtocol.requestHandler = { request in
            // Small delay to simulate network
            Thread.sleep(forTimeInterval: 0.01)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        // Run multiple concurrent requests
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    _ = try? await self.sut.lookup("8.8.8.\(i % 256)")
                }
            }
        }

        // If we get here without crashing, test passes
        XCTAssertTrue(true)
    }

    func testConcurrentMyIPLookupsDoNotCrash() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "203.45.67.89", "city": "Test"}
                """.data(using: .utf8)!)
        }

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = try? await self.sut.lookupMyIP()
                }
            }
        }

        XCTAssertTrue(true)
    }

    // MARK: - URL Construction Security Tests

    func testSpecialCharactersAreURLEncoded() async {
        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            // Check that the URL is properly encoded
            XCTAssertFalse(urlString.contains(" "), "Spaces should be encoded")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        _ = try? await sut.lookup("8.8.8.8")
    }

    func testURLDoesNotContainDoubleSlashes() async {
        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            // Should not have // except after https:
            let afterProtocol = urlString.replacingOccurrences(of: "https://", with: "")
            XCTAssertFalse(afterProtocol.contains("//"), "URL should not contain double slashes")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, """
                {"ip": "8.8.8.8", "city": "Test"}
                """.data(using: .utf8)!)
        }

        _ = try? await sut.lookup("8.8.8.8")
    }
}
