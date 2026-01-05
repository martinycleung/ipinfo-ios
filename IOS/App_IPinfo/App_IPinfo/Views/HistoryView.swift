import SwiftUI

struct HistoryView: View {
    @Bindable var historyManager = HistoryManager.shared
    var onSelect: ((HistoryItem) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if historyManager.history.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                if !historyManager.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All", role: .destructive) {
                            historyManager.clearHistory()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No History",
            systemImage: "clock.arrow.circlepath",
            description: Text("Your IP lookups will appear here")
        )
    }

    private var historyList: some View {
        List {
            ForEach(historyManager.history) { item in
                HistoryRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect?(item)
                        dismiss()
                    }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            historyManager.removeFromHistory(historyManager.history[index])
        }
    }
}

struct HistoryRow: View {
    let item: HistoryItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.ip)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text(item.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let org = item.organization {
                    Text(org)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
