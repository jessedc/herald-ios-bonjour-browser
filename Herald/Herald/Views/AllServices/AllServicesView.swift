import SwiftUI

struct AllServicesView: View {
    @ObservedObject var engine: BonjourDiscoveryEngine
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                DiscoveryStatsSection(
                    chips: [
                        StatChipData(count: engine.allInstances.count, label: "Services", icon: "antenna.radiowaves.left.and.right"),
                        StatChipData(count: engine.serviceTypeCounts.count, label: "Types", icon: "list.bullet")
                    ],
                    errors: engine.errors
                )

                let grouped = groupedInstances
                ForEach(Array(grouped.keys.sorted()), id: \.self) { type in
                    Section {
                        ForEach(grouped[type] ?? []) { instance in
                            NavigationLink(value: instance) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(instance.name)
                                        .font(.body)
                                }
                            }
                            .accessibilityIdentifier("allServices.row")
                        }
                    } header: {
                        HStack {
                            Text(ServiceTypeDescriptions.description(for: type) ?? type)
                            Spacer()
                            Text(type)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .animation(.default, value: engine.allInstances.count)
            .navigationTitle("All Services")
            .navigationDestination(for: ServiceInstance.self) { instance in
                ServiceDetailView(instance: instance)
            }
            .overlay {
                if engine.allInstances.isEmpty && !engine.isScanning {
                    ContentUnavailableView(
                        "No Services Found",
                        systemImage: "antenna.radiowaves.left.and.right.slash"
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Search services")
            .exportable(
                title: "All Services",
                text: { ServiceExporter.plainText(for: self.filteredInstances) },
                json: { ServiceExporter.json(for: self.filteredInstances) }
            )
            .refreshable {
                engine.stopAll()
                engine.startFullScan()
            }
        }
    }

    private var filteredInstances: [ServiceInstance] {
        guard !searchText.isEmpty else { return engine.allInstances }
        return engine.allInstances.filter {
            $0.name.localizedStandardContains(searchText) ||
            $0.type.localizedStandardContains(searchText) ||
            $0.txtRecord.values.contains { $0.localizedStandardContains(searchText) }
        }
    }

    private var groupedInstances: [String: [ServiceInstance]] {
        Dictionary(grouping: filteredInstances, by: { $0.type })
    }
}
