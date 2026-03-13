import SwiftUI

struct StatChip: View {
    let count: Int
    let label: String
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(count)")
                .font(.title2.bold())
                .contentTransition(.numericText())
        }
        VStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorChip: View {
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("\(count)")
                    .font(.title2.bold())
                    .contentTransition(.numericText())
            }
            Text(count == 1 ? "Error" : "Errors")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct DiscoveryStatsSection: View {
    let chips: [StatChipData]
    var errors: [DiscoveryError] = []
    @State private var showingErrors = false

    var body: some View {
        Section {
            HStack(spacing: 0) {
                ForEach(Array(chips.enumerated()), id: \.element.label) { index, chip in
                    if index > 0 {
                        Divider()
                            .frame(height: 30)
                            .padding(.horizontal, 12)
                    }
                    VStack(spacing: 2) {
                        StatChip(count: chip.count, label: chip.label, icon: chip.icon)
                    }
                }
                Spacer()
                if !errors.isEmpty {
                    Button {
                        showingErrors = true
                    } label: {
                        ErrorChip(count: errors.count)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("stats.errorChip")
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingErrors) {
            NavigationStack {
                ErrorListView(errors: errors)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingErrors = false
                            }
                        }
                    }
            }
        }
    }
}

struct StatChipData {
    let count: Int
    let label: String
    var icon: String?
}
