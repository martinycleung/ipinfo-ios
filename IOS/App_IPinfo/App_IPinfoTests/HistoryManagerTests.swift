import XCTest
@testable import App_IPinfo

final class HistoryManagerTests: XCTestCase {

    var sut: HistoryManager!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "ip_lookup_history")
        if let sharedDefaults = UserDefaults(suiteName: "group.com.amazingmartin.ipinfo") {
            sharedDefaults.removeObject(forKey: "ip_lookup_history")
        }
        // Create fresh instance
        sut = HistoryManager.shared
        sut.clearHistory()
    }

    override func tearDown() {
        sut.clearHistory()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testHistoryStartsEmpty() {
        XCTAssertTrue(sut.history.isEmpty)
    }

    func testMostRecentIsNilWhenEmpty() {
        XCTAssertNil(sut.mostRecent)
    }

    // MARK: - Add to History Tests

    func testAddToHistoryAddsItem() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", city: "Mountain View")

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.count, 1)
        XCTAssertEqual(sut.history.first?.ip, "8.8.8.8")
        XCTAssertEqual(sut.history.first?.query, "8.8.8.8")
    }

    func testAddToHistoryStoresLocation() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", city: "Mountain View", region: "California", countryName: "United States")

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.first?.location, "Mountain View, California, United States")
    }

    func testAddToHistoryStoresOrganization() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", org: "GOOGLE")

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.first?.organization, "GOOGLE")
    }

    func testAddToHistoryWithNilOrganization() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", org: nil)

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertNil(sut.history.first?.organization)
    }

    func testAddToHistoryAddsToBeginning() {
        let ipInfo1 = createIPInfo(ip: "1.1.1.1")
        let ipInfo2 = createIPInfo(ip: "2.2.2.2")

        sut.addToHistory(query: "1.1.1.1", ipInfo: ipInfo1)
        sut.addToHistory(query: "2.2.2.2", ipInfo: ipInfo2)

        XCTAssertEqual(sut.history.first?.ip, "2.2.2.2")
        XCTAssertEqual(sut.history.last?.ip, "1.1.1.1")
    }

    func testAddToHistoryRemovesDuplicates() {
        let ipInfo1 = createIPInfo(ip: "8.8.8.8", city: "Old City")
        let ipInfo2 = createIPInfo(ip: "8.8.8.8", city: "New City")

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo1)
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo2)

        XCTAssertEqual(sut.history.count, 1)
        XCTAssertEqual(sut.history.first?.location, "New City")
    }

    func testAddToHistoryKeepsMaxItems() {
        // Add 12 items, should only keep 10
        for i in 1...12 {
            let ipInfo = createIPInfo(ip: "\(i).\(i).\(i).\(i)")
            sut.addToHistory(query: "\(i).\(i).\(i).\(i)", ipInfo: ipInfo)
        }

        XCTAssertEqual(sut.history.count, 10)
        // Most recent should be 12.12.12.12
        XCTAssertEqual(sut.history.first?.ip, "12.12.12.12")
        // Oldest should be 3.3.3.3 (1 and 2 were removed)
        XCTAssertEqual(sut.history.last?.ip, "3.3.3.3")
    }

    func testAddToHistoryWithDomainQuery() {
        let ipInfo = createIPInfo(ip: "142.250.185.46")

        sut.addToHistory(query: "google.com", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.first?.query, "google.com")
        XCTAssertEqual(sut.history.first?.ip, "142.250.185.46")
    }

    func testAddToHistoryWithMyIPQuery() {
        let ipInfo = createIPInfo(ip: "203.45.67.89")

        sut.addToHistory(query: "My IP", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.first?.query, "My IP")
    }

    func testAddToHistoryWithNilIP() {
        let ipInfo = createIPInfo(ip: nil)

        sut.addToHistory(query: "test", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.first?.ip, "Unknown")
    }

    // MARK: - Remove from History Tests

    func testRemoveFromHistoryRemovesItem() {
        let ipInfo = createIPInfo(ip: "8.8.8.8")
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        let item = sut.history.first!
        sut.removeFromHistory(item)

        XCTAssertTrue(sut.history.isEmpty)
    }

    func testRemoveFromHistoryOnlyRemovesMatchingItem() {
        let ipInfo1 = createIPInfo(ip: "1.1.1.1")
        let ipInfo2 = createIPInfo(ip: "2.2.2.2")
        sut.addToHistory(query: "1.1.1.1", ipInfo: ipInfo1)
        sut.addToHistory(query: "2.2.2.2", ipInfo: ipInfo2)

        let itemToRemove = sut.history.first! // 2.2.2.2
        sut.removeFromHistory(itemToRemove)

        XCTAssertEqual(sut.history.count, 1)
        XCTAssertEqual(sut.history.first?.ip, "1.1.1.1")
    }

    // MARK: - Clear History Tests

    func testClearHistoryRemovesAllItems() {
        let ipInfo1 = createIPInfo(ip: "1.1.1.1")
        let ipInfo2 = createIPInfo(ip: "2.2.2.2")
        sut.addToHistory(query: "1.1.1.1", ipInfo: ipInfo1)
        sut.addToHistory(query: "2.2.2.2", ipInfo: ipInfo2)

        sut.clearHistory()

        XCTAssertTrue(sut.history.isEmpty)
    }

    // MARK: - Most Recent Tests

    func testMostRecentReturnsFirstItem() {
        let ipInfo1 = createIPInfo(ip: "1.1.1.1")
        let ipInfo2 = createIPInfo(ip: "2.2.2.2")
        sut.addToHistory(query: "1.1.1.1", ipInfo: ipInfo1)
        sut.addToHistory(query: "2.2.2.2", ipInfo: ipInfo2)

        XCTAssertEqual(sut.mostRecent?.ip, "2.2.2.2")
    }

    // MARK: - HistoryItem Tests

    func testHistoryItemHasUniqueId() {
        let ipInfo = createIPInfo(ip: "8.8.8.8")
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo) // This replaces the previous one

        // Even after replacement, the item should have a valid UUID
        XCTAssertFalse(sut.history.first!.id.uuidString.isEmpty)
    }

    func testHistoryItemTimestamp() {
        let beforeAdd = Date()
        let ipInfo = createIPInfo(ip: "8.8.8.8")
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)
        let afterAdd = Date()

        let timestamp = sut.history.first!.timestamp
        XCTAssertGreaterThanOrEqual(timestamp, beforeAdd)
        XCTAssertLessThanOrEqual(timestamp, afterAdd)
    }

    func testHistoryItemTimeAgo() {
        let ipInfo = createIPInfo(ip: "8.8.8.8")
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        let timeAgo = sut.history.first!.timeAgo
        // Should be something like "now" or "0 sec" or similar
        XCTAssertFalse(timeAgo.isEmpty)
    }

    func testHistoryItemEquality() {
        let ipInfo = createIPInfo(ip: "8.8.8.8")
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        let item1 = sut.history.first!
        let item2 = sut.history.first!

        XCTAssertEqual(item1, item2)
    }

    // MARK: - Persistence Tests

    func testHistoryPersistedToUserDefaults() {
        let ipInfo = createIPInfo(ip: "8.8.8.8")
        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        // Check UserDefaults has data
        let data = UserDefaults.standard.data(forKey: "ip_lookup_history")
        XCTAssertNotNil(data)
    }

    // MARK: - Codable Tests

    func testHistoryItemEncodesAndDecodes() throws {
        let ipInfo = createIPInfo(ip: "8.8.8.8", city: "Mountain View", org: "GOOGLE")
        sut.addToHistory(query: "test query", ipInfo: ipInfo)

        let originalItem = sut.history.first!

        let encoder = JSONEncoder()
        let data = try encoder.encode([originalItem])

        let decoder = JSONDecoder()
        let decodedItems = try decoder.decode([HistoryItem].self, from: data)

        XCTAssertEqual(decodedItems.count, 1)
        XCTAssertEqual(decodedItems.first?.ip, "8.8.8.8")
        XCTAssertEqual(decodedItems.first?.query, "test query")
        XCTAssertEqual(decodedItems.first?.organization, "GOOGLE")
    }

    // MARK: - Edge Cases

    func testAddToHistoryWithEmptyLocation() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", city: nil, region: nil, countryName: nil)

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertEqual(sut.history.first?.location, "Unknown")
    }

    func testAddToHistoryWithSpecialCharacters() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", city: "São Paulo", org: "Company & Co.")

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertTrue(sut.history.first?.location.contains("São Paulo") ?? false)
        XCTAssertEqual(sut.history.first?.organization, "Company & Co.")
    }

    func testAddToHistoryWithUnicode() {
        let ipInfo = createIPInfo(ip: "8.8.8.8", city: "東京", countryName: "日本")

        sut.addToHistory(query: "8.8.8.8", ipInfo: ipInfo)

        XCTAssertTrue(sut.history.first?.location.contains("東京") ?? false)
    }

    // MARK: - Helper Methods

    private func createIPInfo(
        ip: String? = "8.8.8.8",
        city: String? = nil,
        region: String? = nil,
        countryName: String? = nil,
        org: String? = nil
    ) -> IPInfo {
        return IPInfo(
            ip: ip,
            queriedDomain: nil,
            city: city,
            region: region,
            regionCode: nil,
            country: nil,
            countryName: countryName,
            continentCode: nil,
            inEu: nil,
            postal: nil,
            latitude: nil,
            longitude: nil,
            timezone: nil,
            utcOffset: nil,
            countryCallingCode: nil,
            currency: nil,
            languages: nil,
            asn: nil,
            org: org,
            error: nil,
            reason: nil
        )
    }
}
