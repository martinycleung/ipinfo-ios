import SwiftUI

struct IPResultView: View {
    let ipInfo: IPInfo
    @State private var showCopiedToast = false
    @State private var copiedText = ""

    private var displayIP: String {
        ipInfo.ip ?? "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Show domain and IP if it was a domain lookup
                if let domain = ipInfo.queriedDomain {
                    DomainIPCard(domain: domain, ip: displayIP, onCopyDomain: { copyToClipboard(domain, label: "Domain") }, onCopyIP: { copyToClipboard(displayIP, label: "IP") })
                } else {
                    IPAddressCard(ip: displayIP, onCopy: { copyToClipboard(displayIP, label: "IP") })
                }

                LocationCard(ipInfo: ipInfo)

                NetworkCard(ipInfo: ipInfo, onCopy: { text, label in copyToClipboard(text, label: label) })

                MapLocationCard(ipInfo: ipInfo)

                if ipInfo.timezone != nil || ipInfo.currency != nil {
                    AdditionalInfoCard(ipInfo: ipInfo)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("IP Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    copyToClipboard(displayIP, label: "IP")
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                ToastView(message: "\(copiedText) copied!")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCopiedToast)
    }

    private var shareText: String {
        var text: String
        if let domain = ipInfo.queriedDomain {
            text = "IP Information for \(domain)\n"
            text += "Resolved IP: \(displayIP)\n\n"
        } else {
            text = "IP Information for \(displayIP)\n\n"
        }
        text += "Location: \(ipInfo.locationString)\n"
        if let org = ipInfo.org {
            text += "Organization: \(org)\n"
        }
        if let asn = ipInfo.asn {
            text += "ASN: \(asn)\n"
        }
        if let lat = ipInfo.latitude, let lon = ipInfo.longitude {
            text += "Coordinates: \(String(format: "%.4f, %.4f", lat, lon))\n"
        }
        text += "\nLooked up with IP Info app"
        return text
    }

    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        copiedText = label
        showCopiedToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedToast = false
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
    }
}

// MARK: - Domain & IP Card (for domain lookups)

struct DomainIPCard: View {
    let domain: String
    let ip: String
    var onCopyDomain: (() -> Void)? = nil
    var onCopyIP: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Domain Section
            VStack(spacing: 6) {
                Label("Domain", systemImage: "globe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(domain)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)

                    if let onCopyDomain = onCopyDomain {
                        Button {
                            onCopyDomain()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Divider()
                .padding(.horizontal)

            // IP Section
            VStack(spacing: 6) {
                Label("Resolved IP Address", systemImage: "network")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(ip)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)

                    if let onCopyIP = onCopyIP {
                        Button {
                            onCopyIP()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - IP Address Card

struct IPAddressCard: View {
    let ip: String
    var onCopy: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Label("IP Address", systemImage: "network")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Text(ip)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                Spacer()
            }

            if let onCopy = onCopy {
                Button {
                    onCopy()
                } label: {
                    Label("Copy IP", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Location Card

struct LocationCard: View {
    let ipInfo: IPInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "location.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                InfoRow(label: "City", value: ipInfo.city)
                InfoRow(label: "Region", value: ipInfo.region)
                InfoRow(label: "Country", value: ipInfo.countryName ?? ipInfo.country)
                InfoRow(label: "Postal Code", value: ipInfo.postal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Network Card

struct NetworkCard: View {
    let ipInfo: IPInfo
    var onCopy: ((String, String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Network", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                CopyableInfoRow(label: "Organization", value: ipInfo.org, onCopy: onCopy)
                CopyableInfoRow(label: "ASN", value: ipInfo.asn, onCopy: onCopy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Additional Info Card

struct AdditionalInfoCard: View {
    let ipInfo: IPInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Additional Info", systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                InfoRow(label: "Timezone", value: ipInfo.timezone)
                InfoRow(label: "UTC Offset", value: ipInfo.utcOffset)
                InfoRow(label: "Currency", value: ipInfo.currency)
                InfoRow(label: "Calling Code", value: ipInfo.countryCallingCode)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String?

    var body: some View {
        if let value = value, !value.isEmpty {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
    }
}

// MARK: - Copyable Info Row

struct CopyableInfoRow: View {
    let label: String
    let value: String?
    var onCopy: ((String, String) -> Void)? = nil

    var body: some View {
        if let value = value, !value.isEmpty {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
                if let onCopy = onCopy {
                    Button {
                        onCopy(value, label)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .font(.subheadline)
        }
    }
}

#Preview {
    NavigationStack {
        IPResultView(ipInfo: IPInfo(
            ip: "8.8.8.8",
            city: "Mountain View",
            region: "California",
            regionCode: "CA",
            country: "US",
            countryName: "United States",
            continentCode: "NA",
            inEu: false,
            postal: "94035",
            latitude: 37.386,
            longitude: -122.0838,
            timezone: "America/Los_Angeles",
            utcOffset: "-0800",
            countryCallingCode: "+1",
            currency: "USD",
            languages: "en-US",
            asn: "AS15169",
            org: "GOOGLE",
            error: nil,
            reason: nil
        ))
    }
}
