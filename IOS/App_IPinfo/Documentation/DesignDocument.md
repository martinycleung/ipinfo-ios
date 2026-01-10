# Simple IP Info - Design Document

**Version:** 1.0
**Date:** January 2026
**Platform:** iOS 17+
**Framework:** SwiftUI

---

## 1. Executive Summary

Simple IP Info is a native iOS application that provides IP address and domain name geolocation lookup functionality. The app allows users to query any IP address or domain name to retrieve ownership, network, and geographic information with an interactive map visualization.

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ ContentView │  │IPResultView │  │     HistoryView         │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│  ┌──────┴────────────────┴──────────────────────┴─────────────┐  │
│  │                    MapLocationView                          │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                             │
│  ┌─────────────────────────────┐  ┌───────────────────────────┐  │
│  │     IPLookupService         │  │    HistoryManager         │  │
│  │        (Actor)              │  │    (@Observable)          │  │
│  └─────────────────────────────┘  └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                                │
│  ┌─────────────────────────────┐  ┌───────────────────────────┐  │
│  │       IPInfo Model          │  │    HistoryItem Model      │  │
│  │        (Codable)            │  │      (Codable)            │  │
│  └─────────────────────────────┘  └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      External Services                           │
│  ┌─────────────────────────────┐  ┌───────────────────────────┐  │
│  │      ipapi.co API           │  │     ipify.org API         │  │
│  │   (IP Geolocation)          │  │   (Public IP Detection)   │  │
│  └─────────────────────────────┘  └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Component Overview

| Component | Type | Responsibility |
|-----------|------|----------------|
| ContentView | View | Main search interface, input handling |
| IPResultView | View | Results display with detail cards |
| MapLocationView | View | MapKit integration for location |
| HistoryView | View | Search history browser |
| IPLookupService | Actor | API calls, DNS resolution, validation |
| HistoryManager | Observable | History persistence, deduplication |
| IPInfo | Model | API response data structure |
| HistoryItem | Model | Stored search record |

---

## 3. Data Flow

### 3.1 IP/Domain Lookup Flow

```
┌──────────┐    ┌─────────────────┐    ┌──────────────────┐
│  User    │───▶│  ContentView    │───▶│ IPLookupService  │
│  Input   │    │  (sanitize)     │    │ (validate)       │
└──────────┘    └─────────────────┘    └────────┬─────────┘
                                                 │
                        ┌────────────────────────┼────────────────────────┐
                        ▼                        ▼                        ▼
                 ┌────────────┐          ┌────────────┐          ┌────────────┐
                 │  IPv4?     │          │   IPv6?    │          │  Domain?   │
                 └─────┬──────┘          └─────┬──────┘          └─────┬──────┘
                       │                       │                       │
                       │                       │                       ▼
                       │                       │               ┌────────────────┐
                       │                       │               │ DNS Resolution │
                       │                       │               │ (getaddrinfo)  │
                       │                       │               └───────┬────────┘
                       │                       │                       │
                       └───────────────────────┴───────────────────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │    ipapi.co API      │
                                    │  GET /{ip}/json/     │
                                    └──────────┬───────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │   Response Decode    │
                                    │   (JSONDecoder)      │
                                    └──────────┬───────────┘
                                               │
                       ┌───────────────────────┴───────────────────────┐
                       ▼                                               ▼
            ┌──────────────────┐                            ┌──────────────────┐
            │  IPResultView    │                            │  HistoryManager  │
            │  (display)       │                            │  (persist)       │
            └──────────────────┘                            └──────────────────┘
```

### 3.2 State Management

```swift
// ContentView State
@State searchText: String           // User input
@State isLoading: Bool              // Loading indicator
@State ipInfo: IPInfo?              // Current result
@State errorMessage: String?        // Error display
@State showResults: Bool            // Navigation trigger
@State showHistory: Bool            // Sheet presentation

// HistoryManager State (Observable)
@Published history: [HistoryItem]   // Persisted history
```

---

## 4. Data Models

### 4.1 IPInfo Model

```swift
struct IPInfo: Codable, Identifiable {
    // Core
    let ip: String?

    // Location
    let city: String?
    let region: String?
    let regionCode: String?
    let country: String?
    let countryName: String?
    let continentCode: String?
    let postal: String?

    // Coordinates
    let latitude: Double?
    let longitude: Double?

    // Network
    let asn: String?
    let org: String?

    // Temporal
    let timezone: String?
    let utcOffset: String?
    let countryCallingCode: String?

    // Additional
    let currency: String?
    let languages: String?
    let inEu: Bool?

    // API Status
    let error: Bool?
    let reason: String?

    // Non-codable (set by service)
    var queriedDomain: String?
}
```

### 4.2 HistoryItem Model

```swift
struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let query: String           // Original search input
    let ip: String?             // Resolved IP
    let location: String?       // Formatted location
    let organization: String?   // Network org
    let timestamp: Date         // When lookup occurred
}
```

---

## 5. Service Layer Design

### 5.1 IPLookupService (Actor)

The service is implemented as an Actor to ensure thread-safe concurrent access.

```swift
actor IPLookupService {
    private let session: URLSession

    // Public API
    func lookup(_ query: String) async throws -> IPInfo
    func lookupMyIP() async throws -> IPInfo

    // Private Methods
    private func sanitizeInput(_ input: String) -> String
    private func resolveDomain(_ domain: String) async throws -> String
    private func performRequest(url: URL) async throws -> IPInfo
    private func decodeResponse(_ data: Data) throws -> IPInfo
}
```

**Key Design Decisions:**

1. **Actor Isolation**: Prevents data races in concurrent lookups
2. **Dependency Injection**: URLSession passed via initializer for testability
3. **Async/Await**: Non-blocking network operations
4. **DNS Resolution**: Uses POSIX `getaddrinfo` for domain-to-IP resolution

### 5.2 HistoryManager (Observable Singleton)

```swift
@Observable
final class HistoryManager {
    static let shared = HistoryManager()

    private(set) var history: [HistoryItem] = []
    private let maxHistoryItems = 10

    func addToHistory(query: String, ipInfo: IPInfo)
    func removeFromHistory(_ item: HistoryItem)
    func clearHistory()
}
```

**Persistence Strategy:**
- Dual storage: UserDefaults.standard + App Group container
- App Group enables widget access to history
- JSON encoding for serialization

---

## 6. Security Design

### 6.1 Input Validation

| Attack Vector | Mitigation |
|---------------|------------|
| SQL Injection | Character whitelist (alphanumerics, `.`, `-`, `:`) |
| XSS | No HTML rendering; input sanitization |
| Path Traversal | Rejects `..` sequences |
| Command Injection | Blocks shell metacharacters |
| Buffer Overflow | 253 character limit (RFC 1035 compliance) |
| Null Byte Injection | Explicit null byte removal |

### 6.2 Network Security

```swift
// Request Configuration
- Cache Policy: reloadIgnoringLocalCacheData
- Timeout: 15 seconds
- Response Size Limit: 100KB
- HTTPS Only: NSAppTransportSecurity configured
- User-Agent: App_IPinfo/1.0
```

### 6.3 Input Sanitization Pipeline

```
Raw Input
    │
    ├─▶ Trim whitespace
    ├─▶ Remove null bytes
    ├─▶ Check length ≤ 253
    ├─▶ Strip URL prefixes (http://, https://)
    ├─▶ Strip www. prefix
    ├─▶ Block path components (/)
    ├─▶ Validate character whitelist
    │
    ▼
Sanitized Input
```

---

## 7. View Layer Design

### 7.1 Navigation Architecture

```
NavigationStack
    │
    ├── ContentView (Root)
    │       │
    │       ├──▶ IPResultView (Push Navigation)
    │       │       └── MapLocationView (Embedded)
    │       │
    │       └──▶ HistoryView (Sheet Presentation)
    │
    └── Widget (Independent Entry Point)
```

### 7.2 UI Component Hierarchy

```
ContentView
├── HeaderSection
│   ├── Globe Icon (SF Symbol)
│   ├── Title Text
│   └── Subtitle Text
├── SearchSection
│   ├── TextField (monospace)
│   └── Clear Button (conditional)
├── ActionButtonsSection
│   ├── Lookup Button (primary)
│   └── My IP Button (secondary)
├── LoadingSection (conditional)
├── ErrorSection (conditional)
├── RecentSearchesSection
│   └── HorizontalScrollView
│       └── RecentChip[] (max 5)
└── FooterSection
    └── API Attribution

IPResultView
├── DomainIPCard / IPAddressCard
├── LocationCard
│   └── InfoRow[]
├── NetworkCard
│   └── CopyableInfoRow[]
├── MapLocationCard
│   └── MapLocationView / ContentUnavailableView
├── AdditionalInfoCard
│   └── InfoRow[]
└── ToastView (overlay)
```

---

## 8. Widget Architecture

### 8.1 Widget Configuration

```swift
struct IPInfoWidget: Widget {
    let kind: String = "IPInfoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IPInfoProvider()) { entry in
            IPInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simple IP Info")
        .description("View your current IP address and location")
        .supportedFamilies([.systemSmall, .systemMedium,
                           .accessoryCircular, .accessoryRectangular])
    }
}
```

### 8.2 Timeline Refresh Strategy

| Condition | Refresh Interval |
|-----------|------------------|
| Successful fetch | 30 minutes |
| Error/Failure | 5 minutes |
| Widget visible | iOS managed |

### 8.3 Widget Families

| Family | Display |
|--------|---------|
| systemSmall | Icon, "My IP", IP address, location |
| systemMedium | Title, IP, location, organization |
| accessoryCircular | Abbreviated IP (first 2 octets) |
| accessoryRectangular | Icon, "My IP", IP, location |

---

## 9. External API Integration

### 9.1 ipapi.co (Primary)

**Endpoint:** `https://ipapi.co/{ip}/json/`

**Rate Limits:**
- Free tier: 1,000 requests/day
- Per-minute: 30 requests

**Response Fields Used:**
- ip, city, region, region_code, country, country_name
- continent_code, postal, latitude, longitude
- asn, org, timezone, utc_offset
- country_calling_code, currency, languages, in_eu
- error, reason

### 9.2 ipify.org (Secondary)

**Endpoint:** `https://api.ipify.org?format=json`

**Purpose:** Detect user's current public IPv4 address

**Response:**
```json
{ "ip": "203.0.113.45" }
```

---

## 10. Error Handling

### 10.1 Error Types

```swift
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
}
```

### 10.2 Error Presentation

| Error Type | User Message |
|------------|--------------|
| invalidInput | "Invalid IP address or domain" |
| inputTooLong | "Input exceeds maximum length" |
| networkError | "Network connection failed" |
| rateLimited | "Rate limit exceeded. Please try later." |
| dnsResolutionFailed | "Could not resolve domain name" |
| serverError | "Server error. Please try again." |

---

## 11. Accessibility

### 11.1 VoiceOver Support

- All interactive elements have accessibility labels
- Results announced via `UIAccessibility.post(notification:)`
- Semantic grouping for related content

### 11.2 Dynamic Type

- All text uses scalable fonts
- Layout adjusts for larger text sizes

### 11.3 Announcements

```swift
// Success
UIAccessibility.post(notification: .announcement,
    argument: "Your IP address is \(result.ip)")

// Error
UIAccessibility.post(notification: .announcement,
    argument: "Error: \(error.localizedDescription)")
```

---

## 12. Testing Strategy

### 12.1 Test Pyramid

```
        ┌─────────────┐
        │  UI Tests   │  5 screenshot tests
        │             │  20+ functional tests
        ├─────────────┤
        │ Integration │  Mock URLProtocol
        │   Tests     │  Service tests
        ├─────────────┤
        │  Unit       │  Model decoding
        │  Tests      │  Validation logic
        │             │  History management
        └─────────────┘
```

### 12.2 Mock Infrastructure

```swift
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    // Intercepts all URLSession requests during tests
}
```

### 12.3 Test Coverage Areas

| Area | Tests |
|------|-------|
| IPInfo Model | 30+ tests (decoding, computed properties, edge cases) |
| IPLookupService | 35+ tests (API, errors, validation) |
| HistoryManager | 20+ tests (persistence, deduplication) |
| Security | 15+ tests (injection, special characters) |
| UI | 25+ tests (interactions, states, screenshots) |

---

## 13. Performance Considerations

### 13.1 Optimizations

| Area | Optimization |
|------|--------------|
| Network | Cache disabled to ensure fresh data |
| DNS | Background queue for blocking calls |
| History | Limited to 10 items |
| Response | 100KB size limit |
| Map | Lazy camera initialization |
| Widget | 30-minute refresh to respect API limits |

### 13.2 Memory Management

- No retained references between views
- Automatic cleanup via SwiftUI lifecycle
- Bounded history storage

---

## 14. Build Configuration

### 14.1 Project Settings

| Setting | Value |
|---------|-------|
| Bundle ID | com.amazingmartin.ipinfo |
| Team ID | YBL5AWWBNL |
| Deployment Target | iOS 17.0 |
| Swift Version | 5.0 |
| App Group | group.com.amazingmartin.ipinfo |

### 14.2 Build Commands

```bash
# Simulator Build
xcodebuild -scheme App_IPinfo \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Unit Tests
xcodebuild -scheme App_IPinfo \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# Clean Build
xcodebuild -scheme App_IPinfo clean
```

---

## 15. Future Considerations

### 15.1 Potential Enhancements
- IPv6 full support improvements
- Batch IP lookup
- Export history to CSV
- iCloud sync for history
- Favorite/bookmark IPs
- WHOIS integration
- Traceroute visualization

### 15.2 Scalability
- Current architecture supports adding new API providers
- Service layer abstraction enables easy swapping of data sources
- Widget can be extended with additional families

---

## Appendix A: File Structure

```
App_IPinfo/
├── App_IPinfo/
│   ├── App_IPinfoApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   └── IPInfo.swift
│   ├── Services/
│   │   ├── IPLookupService.swift
│   │   └── HistoryManager.swift
│   ├── Views/
│   │   ├── IPResultView.swift
│   │   ├── MapLocationView.swift
│   │   └── HistoryView.swift
│   ├── Assets.xcassets/
│   └── Info.plist
├── IPInfoWidget/
│   └── IPInfoWidget.swift
├── App_IPinfoTests/
│   ├── IPInfoTests.swift
│   ├── IPLookupServiceTests.swift
│   ├── HistoryManagerTests.swift
│   └── SecurityTests.swift
└── App_IPinfoUITests/
    ├── App_IPinfoUITests.swift
    └── ScreenshotTests.swift
```

---

## Appendix B: Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| SwiftUI | Framework | UI |
| MapKit | Framework | Map visualization |
| Foundation | Framework | Networking, POSIX |
| WidgetKit | Framework | Home screen widgets |

No third-party dependencies.
