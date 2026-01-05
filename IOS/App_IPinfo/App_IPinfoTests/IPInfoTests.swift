import XCTest
@testable import App_IPinfo

final class IPInfoTests: XCTestCase {

    // MARK: - Model Decoding Tests

    func testIPInfoDecodingSuccess() throws {
        let json = """
        {
            "ip": "8.8.8.8",
            "city": "Mountain View",
            "region": "California",
            "region_code": "CA",
            "country": "US",
            "country_name": "United States",
            "continent_code": "NA",
            "in_eu": false,
            "postal": "94035",
            "latitude": 37.386,
            "longitude": -122.0838,
            "timezone": "America/Los_Angeles",
            "utc_offset": "-0800",
            "country_calling_code": "+1",
            "currency": "USD",
            "languages": "en-US",
            "asn": "AS15169",
            "org": "GOOGLE"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)

        XCTAssertEqual(ipInfo.ip, "8.8.8.8")
        XCTAssertEqual(ipInfo.city, "Mountain View")
        XCTAssertEqual(ipInfo.region, "California")
        XCTAssertEqual(ipInfo.regionCode, "CA")
        XCTAssertEqual(ipInfo.country, "US")
        XCTAssertEqual(ipInfo.countryName, "United States")
        XCTAssertEqual(ipInfo.continentCode, "NA")
        XCTAssertEqual(ipInfo.inEu, false)
        XCTAssertEqual(ipInfo.postal, "94035")
        XCTAssertEqual(ipInfo.latitude, 37.386)
        XCTAssertEqual(ipInfo.longitude, -122.0838)
        XCTAssertEqual(ipInfo.timezone, "America/Los_Angeles")
        XCTAssertEqual(ipInfo.utcOffset, "-0800")
        XCTAssertEqual(ipInfo.countryCallingCode, "+1")
        XCTAssertEqual(ipInfo.currency, "USD")
        XCTAssertEqual(ipInfo.languages, "en-US")
        XCTAssertEqual(ipInfo.asn, "AS15169")
        XCTAssertEqual(ipInfo.org, "GOOGLE")
    }

    func testIPInfoDecodingWithNullFields() throws {
        let json = """
        {
            "ip": "192.168.1.1",
            "city": null,
            "region": null,
            "country": "US",
            "latitude": null,
            "longitude": null
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)

        XCTAssertEqual(ipInfo.ip, "192.168.1.1")
        XCTAssertNil(ipInfo.city)
        XCTAssertNil(ipInfo.region)
        XCTAssertNil(ipInfo.latitude)
        XCTAssertNil(ipInfo.longitude)
    }

    func testIPInfoDecodingWithMissingFields() throws {
        let json = """
        {
            "ip": "10.0.0.1"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)

        XCTAssertEqual(ipInfo.ip, "10.0.0.1")
        XCTAssertNil(ipInfo.city)
        XCTAssertNil(ipInfo.asn)
        XCTAssertNil(ipInfo.org)
    }

    func testIPInfoDecodingWithError() throws {
        let json = """
        {
            "ip": "invalid",
            "error": true,
            "reason": "Invalid IP address"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)

        XCTAssertEqual(ipInfo.ip, "invalid")
        XCTAssertTrue(ipInfo.error ?? false)
        XCTAssertEqual(ipInfo.reason, "Invalid IP address")
    }

    func testIPInfoDecodingWithNullIP() throws {
        let json = """
        {
            "ip": null,
            "error": true,
            "reason": "Reserved IP"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)

        XCTAssertNil(ipInfo.ip)
        XCTAssertTrue(ipInfo.error ?? false)
    }

    func testIPInfoDecodingWithoutIP() throws {
        let json = """
        {
            "error": true,
            "reason": "No IP provided"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)

        XCTAssertNil(ipInfo.ip)
    }

    // MARK: - Computed Properties Tests

    func testLocationStringWithAllFields() {
        var ipInfo = createIPInfo(city: "Mountain View", region: "California", countryName: "United States")
        XCTAssertEqual(ipInfo.locationString, "Mountain View, California, United States")
    }

    func testLocationStringWithPartialFields() {
        var ipInfo = createIPInfo(city: "Sydney", region: nil, countryName: "Australia")
        XCTAssertEqual(ipInfo.locationString, "Sydney, Australia")
    }

    func testLocationStringWithOnlyCity() {
        var ipInfo = createIPInfo(city: "Tokyo", region: nil, countryName: nil)
        XCTAssertEqual(ipInfo.locationString, "Tokyo")
    }

    func testLocationStringWithOnlyCountry() {
        var ipInfo = createIPInfo(city: nil, region: nil, countryName: "Germany")
        XCTAssertEqual(ipInfo.locationString, "Germany")
    }

    func testLocationStringWithNoFields() {
        var ipInfo = createIPInfo(city: nil, region: nil, countryName: nil)
        XCTAssertEqual(ipInfo.locationString, "Unknown")
    }

    func testHasCoordinatesTrue() {
        var ipInfo = createIPInfo(latitude: 37.386, longitude: -122.0838)
        XCTAssertTrue(ipInfo.hasCoordinates)
    }

    func testHasCoordinatesFalse() {
        var ipInfo = createIPInfo(latitude: nil, longitude: nil)
        XCTAssertFalse(ipInfo.hasCoordinates)
    }

    func testHasCoordinatesPartialLatitude() {
        var ipInfo = createIPInfo(latitude: 37.386, longitude: nil)
        XCTAssertFalse(ipInfo.hasCoordinates)
    }

    func testHasCoordinatesPartialLongitude() {
        var ipInfo = createIPInfo(latitude: nil, longitude: -122.0838)
        XCTAssertFalse(ipInfo.hasCoordinates)
    }

    func testHasCoordinatesWithZeroValues() {
        var ipInfo = createIPInfo(latitude: 0.0, longitude: 0.0)
        XCTAssertTrue(ipInfo.hasCoordinates)
    }

    // MARK: - Identifiable Tests

    func testIdentifiableIdWithIP() {
        var ipInfo = createIPInfo(ip: "8.8.8.8")
        XCTAssertEqual(ipInfo.id, "8.8.8.8")
    }

    func testIdentifiableIdWithNilIP() {
        var ipInfo = createIPInfo(ip: nil)
        // Should return a UUID string when IP is nil
        XCTAssertFalse(ipInfo.id.isEmpty)
        XCTAssertNotEqual(ipInfo.id, "nil")
    }

    // MARK: - QueriedDomain Tests

    func testQueriedDomainIsNotEncodedInJSON() throws {
        var ipInfo = createIPInfo(ip: "8.8.8.8")
        ipInfo.queriedDomain = "google.com"

        let encoder = JSONEncoder()
        let data = try encoder.encode(ipInfo)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        // queriedDomain should not appear in encoded JSON (not in CodingKeys)
        XCTAssertFalse(jsonString.contains("queriedDomain"))
        XCTAssertFalse(jsonString.contains("google.com"))
    }

    func testQueriedDomainDefaultsToNil() throws {
        let json = """
        {"ip": "8.8.8.8"}
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertNil(ipInfo.queriedDomain)
    }

    func testQueriedDomainCanBeSet() {
        var ipInfo = createIPInfo(ip: "8.8.8.8")
        XCTAssertNil(ipInfo.queriedDomain)

        ipInfo.queriedDomain = "example.com"
        XCTAssertEqual(ipInfo.queriedDomain, "example.com")
    }

    // MARK: - Edge Cases

    func testIPv6Address() throws {
        let json = """
        {
            "ip": "2001:4860:4860::8888",
            "city": "Mountain View",
            "country_name": "United States"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(ipInfo.ip, "2001:4860:4860::8888")
    }

    func testPrivateIPAddress() throws {
        let json = """
        {
            "ip": "192.168.1.1",
            "error": true,
            "reason": "Reserved IP Address"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(ipInfo.ip, "192.168.1.1")
        XCTAssertTrue(ipInfo.error ?? false)
    }

    func testSpecialCharactersInOrg() throws {
        let json = """
        {
            "ip": "1.2.3.4",
            "org": "Company & Co. <Test>"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(ipInfo.org, "Company & Co. <Test>")
    }

    func testUnicodeInCity() throws {
        let json = """
        {
            "ip": "1.2.3.4",
            "city": "東京",
            "country_name": "日本"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(ipInfo.city, "東京")
        XCTAssertEqual(ipInfo.countryName, "日本")
    }

    func testEmptyStringFields() throws {
        let json = """
        {
            "ip": "1.2.3.4",
            "city": "",
            "org": ""
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(ipInfo.city, "")
        XCTAssertEqual(ipInfo.org, "")
    }

    func testNegativeCoordinates() throws {
        let json = """
        {
            "ip": "1.2.3.4",
            "latitude": -33.8688,
            "longitude": 151.2093
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(ipInfo.latitude, -33.8688)
        XCTAssertEqual(ipInfo.longitude, 151.2093)
    }

    func testInEuTrue() throws {
        let json = """
        {
            "ip": "1.2.3.4",
            "in_eu": true,
            "country_name": "Germany"
        }
        """.data(using: .utf8)!

        let ipInfo = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertTrue(ipInfo.inEu ?? false)
    }

    // MARK: - Helper Methods

    private func createIPInfo(
        ip: String? = "8.8.8.8",
        city: String? = "Mountain View",
        region: String? = "California",
        regionCode: String? = "CA",
        country: String? = "US",
        countryName: String? = "United States",
        continentCode: String? = "NA",
        inEu: Bool? = false,
        postal: String? = "94035",
        latitude: Double? = 37.386,
        longitude: Double? = -122.0838,
        timezone: String? = "America/Los_Angeles",
        utcOffset: String? = "-0800",
        countryCallingCode: String? = "+1",
        currency: String? = "USD",
        languages: String? = "en-US",
        asn: String? = "AS15169",
        org: String? = "GOOGLE",
        error: Bool? = nil,
        reason: String? = nil
    ) -> IPInfo {
        return IPInfo(
            ip: ip,
            queriedDomain: nil,
            city: city,
            region: region,
            regionCode: regionCode,
            country: country,
            countryName: countryName,
            continentCode: continentCode,
            inEu: inEu,
            postal: postal,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            utcOffset: utcOffset,
            countryCallingCode: countryCallingCode,
            currency: currency,
            languages: languages,
            asn: asn,
            org: org,
            error: error,
            reason: reason
        )
    }
}
