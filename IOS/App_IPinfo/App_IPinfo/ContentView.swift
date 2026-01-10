import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var ipInfo: IPInfo?
    @State private var errorMessage: String?
    @State private var showResults = false
    @State private var showHistory = false
    @Bindable private var historyManager = HistoryManager.shared

    private let lookupService = IPLookupService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                searchSection

                actionButtons

                if isLoading {
                    loadingSection
                }

                if let error = errorMessage {
                    errorSection(error)
                }

                if !historyManager.history.isEmpty {
                    recentSearchesSection
                }

                Spacer()

                footerSection
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Simple IP Info")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .disabled(historyManager.history.isEmpty)
                }
            }
            .navigationDestination(isPresented: $showResults) {
                if let ipInfo = ipInfo {
                    IPResultView(ipInfo: ipInfo)
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView { item in
                    searchText = item.query
                    performLookup()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
                .accessibilityHidden(true)

            Text("IP Address Lookup")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            Text("Enter an IP address or domain name")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("8.8.8.8 or google.com", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .submitLabel(.search)
                    .onSubmit {
                        performLookup()
                    }
                    .accessibilityLabel("IP address or domain name")
                    .accessibilityHint("Enter an IP address like 8.8.8.8 or a domain name like google.com")

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search field")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                performLookup()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    Text(isLoading ? "Looking up..." : "Lookup")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(searchText.isEmpty || isLoading ? Color.gray : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(searchText.isEmpty || isLoading)
            .accessibilityLabel(isLoading ? "Looking up IP address" : "Lookup IP address")
            .accessibilityHint(searchText.isEmpty ? "Enter an IP address or domain first" : "Double tap to look up \(searchText)")

            Button {
                lookupMyIP()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text("My IP Address")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .disabled(isLoading)
            .accessibilityLabel("Look up my IP address")
            .accessibilityHint("Double tap to find your current IP address")
        }
    }

    // MARK: - Recent Searches Section

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("See All") {
                    showHistory = true
                }
                .font(.caption)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(historyManager.history.prefix(5)) { item in
                        RecentChip(item: item) {
                            searchText = item.query
                            performLookup()
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Looking up...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading, please wait")
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Powered by ipapi.co")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Free tier: 1,000 requests/day")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Powered by ipapi.co. Free tier allows 1,000 requests per day.")
    }

    // MARK: - Actions

    private func performLookup() {
        guard !searchText.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        let query = searchText

        Task {
            do {
                let result = try await lookupService.lookup(searchText)
                await MainActor.run {
                    ipInfo = result
                    isLoading = false
                    showResults = true
                    historyManager.addToHistory(query: query, ipInfo: result)
                    UIAccessibility.post(notification: .announcement, argument: "IP information loaded for \(result.ip ?? "unknown")")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    UIAccessibility.post(notification: .announcement, argument: "Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func lookupMyIP() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await lookupService.lookupMyIP()
                await MainActor.run {
                    ipInfo = result
                    searchText = result.ip ?? ""
                    isLoading = false
                    showResults = true
                    historyManager.addToHistory(query: result.ip ?? "My IP", ipInfo: result)
                    UIAccessibility.post(notification: .announcement, argument: "Your IP address is \(result.ip ?? "unknown")")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    UIAccessibility.post(notification: .announcement, argument: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Recent Chip

struct RecentChip: View {
    let item: HistoryItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.caption2)
                Text(item.query)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
