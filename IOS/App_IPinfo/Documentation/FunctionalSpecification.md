# Simple IP Info - Functional Specification

**Version:** 1.0
**Date:** January 2026
**Document Status:** Final

---

## 1. Introduction

### 1.1 Purpose
This document defines the functional requirements and specifications for Simple IP Info, an iOS application for IP address and domain name geolocation lookup.

### 1.2 Scope
Simple IP Info enables users to:
- Look up geographic and network information for any IP address
- Resolve domain names and retrieve their IP information
- View location data on an interactive map
- Maintain a history of recent searches
- View current IP information via a home screen widget

### 1.3 Target Audience
- Network administrators
- Software developers
- Security professionals
- General users curious about IP geolocation

### 1.4 Platform Requirements
- iOS 17.0 or later
- iPhone and iPad compatible
- Internet connection required

---

## 2. User Roles

### 2.1 End User
The primary user who interacts with the app to perform IP/domain lookups.

**Capabilities:**
- Enter IP addresses or domain names for lookup
- View detailed geolocation results
- Copy and share lookup results
- Browse and manage search history
- Configure home screen widget

---

## 3. Functional Requirements

### 3.1 Home Screen (FR-HOME)

#### FR-HOME-001: Search Input
**Description:** The app shall provide a text input field for entering IP addresses or domain names.

**Acceptance Criteria:**
- Text field accepts alphanumeric characters, dots, hyphens, and colons
- Monospace font for clarity
- ASCII keyboard presented by default
- Clear button appears when text is entered
- Maximum input length: 253 characters

#### FR-HOME-002: Lookup Button
**Description:** A primary action button to initiate the lookup.

**Acceptance Criteria:**
- Button labeled "Lookup"
- Disabled when input field is empty
- Disabled during active lookup
- Blue filled style (primary action)

#### FR-HOME-003: My IP Button
**Description:** A secondary button to look up the user's current public IP address.

**Acceptance Criteria:**
- Button labeled "My IP Address"
- Disabled during active lookup
- Outlined style (secondary action)
- Retrieves user's current public IPv4 address

#### FR-HOME-004: Loading Indicator
**Description:** Visual feedback during lookup operations.

**Acceptance Criteria:**
- Spinner animation displayed
- "Looking up..." text shown
- Lookup and My IP buttons disabled
- Disappears when operation completes

#### FR-HOME-005: Error Display
**Description:** Error messages shown when lookup fails.

**Acceptance Criteria:**
- Orange/warning colored container
- Alert icon with error text
- Dismissible (disappears on next action)
- Human-readable error messages

#### FR-HOME-006: Recent Searches
**Description:** Quick access to recent search queries.

**Acceptance Criteria:**
- Horizontal scrollable list of chips
- Shows last 5 searches
- Tapping chip populates search field and triggers lookup
- Hidden when no history exists

#### FR-HOME-007: History Access
**Description:** Navigation to full history view.

**Acceptance Criteria:**
- Clock icon button in toolbar
- Disabled when history is empty
- Opens history sheet when tapped

---

### 3.2 IP/Domain Lookup (FR-LOOKUP)

#### FR-LOOKUP-001: IPv4 Address Lookup
**Description:** Support lookup of IPv4 addresses.

**Acceptance Criteria:**
- Accepts format: `X.X.X.X` where X is 0-255
- Validates proper IPv4 format
- Rejects leading zeros (e.g., `08.08.08.08`)
- Examples: `8.8.8.8`, `192.168.1.1`, `203.0.113.45`

#### FR-LOOKUP-002: IPv6 Address Lookup
**Description:** Support lookup of IPv6 addresses.

**Acceptance Criteria:**
- Accepts standard IPv6 notation
- Supports abbreviated formats
- Examples: `2001:4860:4860::8888`, `::1`

#### FR-LOOKUP-003: Domain Name Lookup
**Description:** Support lookup of domain names with automatic DNS resolution.

**Acceptance Criteria:**
- Accepts valid domain name formats
- Performs DNS resolution to obtain IP address
- Displays both domain and resolved IP in results
- Examples: `google.com`, `example.org`, `sub.domain.co.uk`

#### FR-LOOKUP-004: Input Sanitization
**Description:** Clean and validate user input before processing.

**Acceptance Criteria:**
- Trim leading/trailing whitespace
- Remove URL prefixes (`http://`, `https://`)
- Remove `www.` prefix
- Block path components (`/`)
- Reject special characters outside whitelist
- Maximum 253 characters

#### FR-LOOKUP-005: My IP Detection
**Description:** Detect and look up user's current public IP.

**Acceptance Criteria:**
- Retrieves current public IPv4 from ipify.org
- Performs full geolocation lookup on detected IP
- Auto-populates search field with detected IP

---

### 3.3 Results Display (FR-RESULTS)

#### FR-RESULTS-001: IP Address Display
**Description:** Show the queried/resolved IP address prominently.

**Acceptance Criteria:**
- Large monospace font
- Copy button adjacent
- For domain lookups: show both domain and resolved IP
- For IP lookups: show IP only

#### FR-RESULTS-002: Location Information
**Description:** Display geographic location details.

**Acceptance Criteria:**
| Field | Description |
|-------|-------------|
| City | City name |
| Region | State/province/region |
| Country | Full country name |
| Postal Code | ZIP/postal code |

- Hidden rows for null/empty values
- Tappable for clipboard copy

#### FR-RESULTS-003: Network Information
**Description:** Display network ownership details.

**Acceptance Criteria:**
| Field | Description |
|-------|-------------|
| Organization | ISP/network owner |
| ASN | Autonomous System Number |

- Copy button for each field
- Monospace font for ASN

#### FR-RESULTS-004: Map Visualization
**Description:** Display IP location on an interactive map.

**Acceptance Criteria:**
- MapKit integration
- Red marker at IP coordinates
- 0.5 degree zoom span
- Compass and scale controls
- "No Location Data" message if coordinates unavailable
- Coordinates displayed below map

#### FR-RESULTS-005: Additional Information
**Description:** Display supplementary details.

**Acceptance Criteria:**
| Field | Description |
|-------|-------------|
| Timezone | IANA timezone identifier |
| UTC Offset | Time offset from UTC |
| Currency | Local currency code |
| Calling Code | International dialing code |

#### FR-RESULTS-006: Share Functionality
**Description:** Share lookup results via system share sheet.

**Acceptance Criteria:**
- Share button in toolbar
- Includes: IP, domain (if applicable), location, organization, ASN, coordinates
- App attribution text included
- Uses native iOS share sheet

#### FR-RESULTS-007: Copy Functionality
**Description:** Copy individual fields to clipboard.

**Acceptance Criteria:**
- Tap-to-copy for IP address
- Copy buttons for org and ASN fields
- Toast notification confirming copy
- Haptic feedback

---

### 3.4 History Management (FR-HISTORY)

#### FR-HISTORY-001: History Storage
**Description:** Persist search history locally.

**Acceptance Criteria:**
- Store last 10 lookups
- Persisted across app launches
- Stored in UserDefaults
- Shared with widget via App Group

#### FR-HISTORY-002: History Item Data
**Description:** Data stored for each history item.

**Acceptance Criteria:**
| Field | Description |
|-------|-------------|
| Query | Original search input |
| IP | Resolved IP address |
| Location | Formatted location string |
| Organization | Network owner |
| Timestamp | When lookup occurred |

#### FR-HISTORY-003: Deduplication
**Description:** Prevent duplicate entries in history.

**Acceptance Criteria:**
- Duplicates identified by resolved IP
- Existing entry moved to top on repeat lookup
- Timestamp updated

#### FR-HISTORY-004: History View
**Description:** Full-screen history browser.

**Acceptance Criteria:**
- List of all history items
- Grouped list style
- Swipe-to-delete individual items
- "Clear All" button to delete all history
- Empty state when no history
- Tap item to re-run lookup

#### FR-HISTORY-005: History Item Display
**Description:** Information shown for each history item.

**Acceptance Criteria:**
- Query text (monospace)
- Resolved IP (if different from query)
- Location (truncated if long)
- Organization (truncated if long)
- Relative timestamp ("2 hours ago")
- Globe icon indicator

---

### 3.5 Widget (FR-WIDGET)

#### FR-WIDGET-001: Widget Families
**Description:** Support multiple widget sizes.

**Acceptance Criteria:**
| Family | Support |
|--------|---------|
| systemSmall | Yes |
| systemMedium | Yes |
| accessoryCircular | Yes (Lock Screen) |
| accessoryRectangular | Yes (Lock Screen) |

#### FR-WIDGET-002: Widget Content - Small
**Description:** Content for small widget.

**Acceptance Criteria:**
- Globe icon
- "My IP" label
- Current IP address
- Location (city, country)

#### FR-WIDGET-003: Widget Content - Medium
**Description:** Content for medium widget.

**Acceptance Criteria:**
- App title
- Current IP address
- Full location string
- Organization name
- Location icon

#### FR-WIDGET-004: Widget Refresh
**Description:** Automatic data refresh.

**Acceptance Criteria:**
- Refresh every 30 minutes on success
- Refresh every 5 minutes on error
- Fetches current public IP
- Performs geolocation lookup

#### FR-WIDGET-005: Widget Tap Action
**Description:** Behavior when widget is tapped.

**Acceptance Criteria:**
- Opens main app
- (Future: Deep link to results)

---

### 3.6 Error Handling (FR-ERROR)

#### FR-ERROR-001: Invalid Input
**Description:** Handle invalid user input.

**Acceptance Criteria:**
- Message: "Invalid IP address or domain name"
- Displayed in error container
- Input field retained for correction

#### FR-ERROR-002: Network Errors
**Description:** Handle network connectivity issues.

**Acceptance Criteria:**
- Message: "Network error. Please check your connection."
- Retry possible without re-entering input

#### FR-ERROR-003: Rate Limiting
**Description:** Handle API rate limit exceeded.

**Acceptance Criteria:**
- Message: "Rate limit exceeded. Please try again later."
- HTTP 429 response detected

#### FR-ERROR-004: DNS Resolution Failure
**Description:** Handle domain name resolution failures.

**Acceptance Criteria:**
- Message: "Could not resolve domain name"
- Specific to domain lookups only

#### FR-ERROR-005: Server Errors
**Description:** Handle API server errors.

**Acceptance Criteria:**
- Message: "Server error. Please try again."
- HTTP 5xx responses

---

## 4. Non-Functional Requirements

### 4.1 Performance (NFR-PERF)

#### NFR-PERF-001: Response Time
**Description:** Lookup operations complete within acceptable time.

**Acceptance Criteria:**
- Typical lookup: < 3 seconds
- DNS resolution: < 5 seconds
- Request timeout: 15 seconds

#### NFR-PERF-002: Resource Usage
**Description:** Minimal impact on device resources.

**Acceptance Criteria:**
- Response size limit: 100KB
- History limit: 10 items
- No background processing except widget

---

### 4.2 Security (NFR-SEC)

#### NFR-SEC-001: Input Validation
**Description:** Protect against injection attacks.

**Acceptance Criteria:**
- SQL injection patterns blocked
- XSS patterns blocked
- Path traversal blocked
- Command injection blocked
- Null byte injection blocked

#### NFR-SEC-002: Network Security
**Description:** Secure network communications.

**Acceptance Criteria:**
- HTTPS only
- Certificate validation enabled
- No sensitive data in URLs

#### NFR-SEC-003: Data Privacy
**Description:** Protect user privacy.

**Acceptance Criteria:**
- No personal data collected
- No analytics or tracking
- History stored locally only
- No cloud sync

---

### 4.3 Accessibility (NFR-ACC)

#### NFR-ACC-001: VoiceOver Support
**Description:** Full VoiceOver compatibility.

**Acceptance Criteria:**
- All UI elements labeled
- Logical navigation order
- Results announced on completion
- Errors announced

#### NFR-ACC-002: Dynamic Type
**Description:** Support system font size settings.

**Acceptance Criteria:**
- All text scales with system settings
- Layout adapts to larger sizes
- No text truncation at accessibility sizes

#### NFR-ACC-003: Color Accessibility
**Description:** Accessible color usage.

**Acceptance Criteria:**
- Sufficient contrast ratios
- Information not conveyed by color alone
- Support for color blindness

---

### 4.4 Localization (NFR-LOC)

#### NFR-LOC-001: Language Support
**Description:** Current language support.

**Acceptance Criteria:**
- English (primary)
- Future: Localization-ready architecture

---

## 5. Use Cases

### UC-001: Look Up IP Address

**Actor:** End User
**Precondition:** App is open, network available
**Trigger:** User wants to know details about an IP address

**Main Flow:**
1. User enters IP address in search field (e.g., "8.8.8.8")
2. User taps "Lookup" button
3. System validates input format
4. System sends request to geolocation API
5. System displays results view with:
   - IP address
   - Location (city, region, country)
   - Network (organization, ASN)
   - Map with location marker
   - Additional details
6. System adds lookup to history

**Alternative Flow 3a:** Invalid IP format
1. System displays error: "Invalid IP address or domain name"
2. User corrects input
3. Resume at step 2

**Alternative Flow 4a:** Network error
1. System displays error: "Network error"
2. User retries when connectivity restored

**Postcondition:** User has viewed IP geolocation information

---

### UC-002: Look Up Domain Name

**Actor:** End User
**Precondition:** App is open, network available
**Trigger:** User wants to know IP and location for a domain

**Main Flow:**
1. User enters domain name (e.g., "google.com")
2. User taps "Lookup" button
3. System validates domain format
4. System performs DNS resolution
5. System obtains resolved IP address
6. System sends request to geolocation API with resolved IP
7. System displays results showing both domain and resolved IP
8. System adds lookup to history (with domain as query)

**Alternative Flow 4a:** DNS resolution fails
1. System displays error: "Could not resolve domain name"
2. User verifies domain spelling

**Postcondition:** User has viewed domain's IP geolocation

---

### UC-003: Look Up My IP

**Actor:** End User
**Precondition:** App is open, network available
**Trigger:** User wants to know their current public IP

**Main Flow:**
1. User taps "My IP Address" button
2. System detects public IPv4 via ipify.org
3. System performs geolocation lookup on detected IP
4. System displays results
5. System populates search field with detected IP
6. System adds to history

**Alternative Flow 2a:** IP detection fails
1. System displays error: "Could not detect your IP address"

**Postcondition:** User knows their public IP and its geolocation

---

### UC-004: View Search History

**Actor:** End User
**Precondition:** At least one previous lookup exists
**Trigger:** User wants to see past lookups

**Main Flow:**
1. User taps history icon in toolbar
2. System displays history sheet
3. User scrolls through history list
4. User taps a history item
5. System closes sheet
6. System performs lookup for selected item

**Alternative Flow 3a:** Delete item
1. User swipes left on item
2. User taps "Delete"
3. System removes item from history

**Alternative Flow 3b:** Clear all history
1. User taps "Clear All" button
2. System removes all history items
3. System shows empty state

**Postcondition:** User has interacted with history

---

### UC-005: Share Results

**Actor:** End User
**Precondition:** Results view is displayed
**Trigger:** User wants to share lookup results

**Main Flow:**
1. User taps share button in toolbar
2. System generates formatted text with all details
3. System presents iOS share sheet
4. User selects sharing method (Messages, Email, etc.)
5. System shares content via selected method

**Postcondition:** Results shared to selected destination

---

### UC-006: Copy IP to Clipboard

**Actor:** End User
**Precondition:** Results view is displayed
**Trigger:** User wants to copy IP address

**Main Flow:**
1. User taps copy button next to IP address
2. System copies IP to clipboard
3. System displays toast: "IP copied"
4. Toast auto-dismisses after 1.5 seconds

**Postcondition:** IP address is in clipboard

---

### UC-007: View Widget

**Actor:** End User
**Precondition:** Widget added to home screen
**Trigger:** User glances at home screen

**Main Flow:**
1. Widget displays current IP address
2. Widget displays location
3. Widget refreshes automatically every 30 minutes

**Alternative Flow 1a:** Network unavailable
1. Widget displays last known data or placeholder
2. Widget retries in 5 minutes

**Postcondition:** User has viewed current IP information

---

## 6. Data Specifications

### 6.1 API Response Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| ip | String | IP address | "8.8.8.8" |
| city | String? | City name | "Mountain View" |
| region | String? | Region/state | "California" |
| region_code | String? | Region abbreviation | "CA" |
| country | String? | Country code | "US" |
| country_name | String? | Full country name | "United States" |
| continent_code | String? | Continent code | "NA" |
| postal | String? | Postal/ZIP code | "94035" |
| latitude | Double? | Latitude | 37.386 |
| longitude | Double? | Longitude | -122.0838 |
| timezone | String? | IANA timezone | "America/Los_Angeles" |
| utc_offset | String? | UTC offset | "-0700" |
| country_calling_code | String? | Dialing code | "+1" |
| currency | String? | Currency code | "USD" |
| languages | String? | Languages | "en-US" |
| asn | String? | AS Number | "AS15169" |
| org | String? | Organization | "Google LLC" |
| in_eu | Bool? | EU membership | false |
| error | Bool? | Error flag | false |
| reason | String? | Error message | "Rate limited" |

### 6.2 History Item Fields

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| query | String | Original search input |
| ip | String? | Resolved IP address |
| location | String? | "City, Region, Country" |
| organization | String? | Network owner |
| timestamp | Date | Lookup timestamp |

---

## 7. UI Specifications

### 7.1 Color Palette

| Element | Color | Usage |
|---------|-------|-------|
| Primary | System Blue | Buttons, links |
| Secondary | System Gray | Secondary text |
| Background | System Grouped Background | Main background |
| Card | System Background | Card containers |
| Error | System Orange | Error messages |
| Success | System Green | Success indicators |

### 7.2 Typography

| Element | Style | Font |
|---------|-------|------|
| Navigation Title | Large Title | System |
| Section Headers | Headline | System |
| Body Text | Body | System |
| IP Address | Title | Monospace |
| Labels | Subheadline | System |
| Secondary | Footnote | System |

### 7.3 Spacing

| Element | Value |
|---------|-------|
| Screen padding | 16pt |
| Card padding | 16pt |
| Card spacing | 12pt |
| Row spacing | 8pt |
| Icon size | 24pt |

---

## 8. Validation Rules

### 8.1 IPv4 Validation

```
Pattern: ^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$
```

**Rules:**
- Four octets separated by dots
- Each octet: 0-255
- No leading zeros (08 invalid)
- No trailing dots

### 8.2 IPv6 Validation

**Rules:**
- Contains at least one colon
- Only hexadecimal digits and colons
- Maximum 8 groups
- Supports :: abbreviation

### 8.3 Domain Validation

```
Pattern: ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$
```

**Rules:**
- Starts with alphanumeric
- Contains only alphanumerics and hyphens
- Has at least one dot
- TLD minimum 2 characters
- Maximum 253 characters total

---

## 9. Test Scenarios

### 9.1 Functional Tests

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| FT-001 | Enter valid IPv4 | Results displayed |
| FT-002 | Enter valid IPv6 | Results displayed |
| FT-003 | Enter valid domain | Resolved IP and results displayed |
| FT-004 | Enter invalid input | Error message shown |
| FT-005 | Tap My IP | Current IP detected and results shown |
| FT-006 | View history | History list displayed |
| FT-007 | Delete history item | Item removed |
| FT-008 | Clear all history | All items removed |
| FT-009 | Share results | Share sheet appears |
| FT-010 | Copy IP | Toast confirms copy |

### 9.2 Edge Case Tests

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| EC-001 | Empty input | Lookup button disabled |
| EC-002 | 254+ character input | Error: input too long |
| EC-003 | SQL injection attempt | Error: invalid input |
| EC-004 | Private IP (192.168.x.x) | Limited geolocation data |
| EC-005 | Nonexistent domain | DNS resolution error |
| EC-006 | Network offline | Network error displayed |
| EC-007 | API rate limited | Rate limit error displayed |

### 9.3 Widget Tests

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| WT-001 | Widget initial load | IP and location displayed |
| WT-002 | Widget refresh | Data updated |
| WT-003 | Widget tap | App opens |
| WT-004 | Widget offline | Last data or placeholder shown |

---

## 10. Glossary

| Term | Definition |
|------|------------|
| ASN | Autonomous System Number - unique identifier for a network |
| DNS | Domain Name System - translates domain names to IP addresses |
| IPv4 | Internet Protocol version 4 - 32-bit address format |
| IPv6 | Internet Protocol version 6 - 128-bit address format |
| Geolocation | Process of determining physical location from IP address |
| ISP | Internet Service Provider |
| TLD | Top-Level Domain (e.g., .com, .org) |
| Widget | iOS home screen or lock screen mini-application |

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | January 2026 | - | Initial release |

---

## 12. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| QA Lead | | | |
