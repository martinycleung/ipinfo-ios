# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IP Info is an iOS app (iOS 17+) built with SwiftUI that allows users to lookup IP address or domain name information including owner, ASN, and geographic location with MapKit visualization.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -scheme App_IPinfo -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests
xcodebuild -scheme App_IPinfo -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -scheme App_IPinfo -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:App_IPinfoTests/IPInfoTests test

# Clean build
xcodebuild -scheme App_IPinfo clean
```

## Architecture

### Data Flow
1. User enters IP address or domain in `ContentView`
2. `IPLookupService` (actor) sanitizes input and determines if it's IP or domain
3. For domains: DNS resolution via `getaddrinfo` → resolved IP
4. API call to ipapi.co with IP → `IPInfo` model
5. Results displayed in `IPResultView` with `MapLocationView`

### Key Components

**Models/**
- `IPInfo.swift` - Codable model for ipapi.co JSON response. The `queriedDomain` property (not in CodingKeys) stores the original domain for display.

**Services/**
- `IPLookupService.swift` - Actor handling API calls. Key methods:
  - `lookup(_:)` - Main entry point, handles both IP and domain inputs
  - `resolveDomain(_:)` - DNS resolution using POSIX `getaddrinfo`
  - `sanitizeInput(_:)` - Strips URL prefixes, www., validates characters
- `HistoryManager.swift` - @Observable singleton storing last 10 lookups in UserDefaults (with App Group support for widgets)

**Views/**
- `ContentView.swift` - Main screen with search field, lookup buttons, recent searches
- `IPResultView.swift` - Results display with `DomainIPCard` (domain lookups) or `IPAddressCard` (IP lookups)
- `MapLocationView.swift` - MapKit integration showing IP location
- `HistoryView.swift` - Full search history list

### External API
- **ipapi.co** - IP geolocation API (free tier: 1,000 requests/day)
- Only accepts IP addresses, not domain names (app handles DNS resolution)
- Endpoint: `https://ipapi.co/{ip}/json/`

### Widget Extension
`IPInfoWidget/` contains prepared widget code but requires manual Xcode target setup:
1. File → New → Target → Widget Extension
2. Replace generated code with `IPInfoWidget.swift` contents

## Testing

Test targets:
- `App_IPinfoTests/` - Unit tests for models and services (uses mock URLProtocol)
- `App_IPinfoUITests/` - UI automation tests

## Bundle Configuration
- Bundle ID: `com.amazingmartin.ipinfo`
- Development Team: `YBL5AWWBNL`
- App Group (for widget): `group.com.amazingmartin.ipinfo`
