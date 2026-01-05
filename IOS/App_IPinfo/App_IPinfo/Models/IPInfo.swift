import Foundation

struct IPInfo: Codable, Identifiable {
    var id: String { ip ?? UUID().uuidString }

    let ip: String?

    // Non-codable property to store original query (domain name)
    var queriedDomain: String?
    let city: String?
    let region: String?
    let regionCode: String?
    let country: String?
    let countryName: String?
    let continentCode: String?
    let inEu: Bool?
    let postal: String?
    let latitude: Double?
    let longitude: Double?
    let timezone: String?
    let utcOffset: String?
    let countryCallingCode: String?
    let currency: String?
    let languages: String?
    let asn: String?
    let org: String?
    let error: Bool?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case ip, city, region, country, postal, latitude, longitude, timezone, currency, languages, asn, org, error, reason
        case regionCode = "region_code"
        case countryName = "country_name"
        case continentCode = "continent_code"
        case inEu = "in_eu"
        case utcOffset = "utc_offset"
        case countryCallingCode = "country_calling_code"
    }

    var locationString: String {
        var parts: [String] = []
        if let city = city { parts.append(city) }
        if let region = region { parts.append(region) }
        if let countryName = countryName { parts.append(countryName) }
        return parts.isEmpty ? "Unknown" : parts.joined(separator: ", ")
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}
