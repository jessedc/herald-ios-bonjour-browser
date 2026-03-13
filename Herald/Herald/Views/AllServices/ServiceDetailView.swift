import SwiftUI

struct ServiceDetailView: View {
    @StateObject private var viewModel: ServiceDetailViewModel

    init(instance: ServiceInstance) {
        _viewModel = StateObject(wrappedValue: ServiceDetailViewModel(instance: instance))
    }

    var body: some View {
        List {
            // Basic Info
            Section("Service") {
                LabeledRow(label: "Name", value: viewModel.instance.name)
                LabeledRow(label: "Type", value: viewModel.instance.type)
                LabeledRow(label: "Domain", value: viewModel.instance.domain)

                if let description = ServiceTypeDescriptions.description(for: viewModel.instance.type) {
                    LabeledRow(label: "Description", value: description)
                }
            }

            ServiceEnrichmentSection(instance: viewModel.enrichedInstance)

            // Resolved Details
            if viewModel.isResolving {
                Section("Resolving…") {
                    HStack {
                        ProgressView()
                        Text("Looking up hostname and addresses…")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("detail.resolving")
            }

            if let error = viewModel.resolverError {
                ErrorRow(message: error) {
                    viewModel.resolve()
                }
            }

            if let resolved = viewModel.resolved {
                Section("Connection") {
                    LabeledRow(label: "Hostname", value: resolved.hostname)
                    LabeledRow(label: "Port", value: resolved.formattedPort)
                }
                .accessibilityIdentifier("detail.connection")

                if !resolved.ipv4Addresses.isEmpty {
                    Section("IPv4 Addresses") {
                        ForEach(resolved.ipv4Addresses, id: \.self) { addr in
                            Text(addr)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }

                if !resolved.ipv6Addresses.isEmpty {
                    Section("IPv6 Addresses") {
                        ForEach(resolved.ipv6Addresses, id: \.self) { addr in
                            Text(addr)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            // TXT Record
            if !viewModel.txtRecord.isEmpty {
                Section("TXT Record") {
                    ForEach(
                        viewModel.txtRecord.sorted(by: { $0.key < $1.key }),
                        id: \.key
                    ) { key, value in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(TXTRecordLabels.displayKey(for: key, serviceType: viewModel.instance.type))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(value.isEmpty ? "(empty)" : value)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.instance.name)
        .navigationBarTitleDisplayMode(.inline)
        .exportable(title: viewModel.exportTitle, text: { viewModel.exportText }, json: { viewModel.exportJSON ?? "" })
        .onAppear {
            viewModel.resolve()
        }
    }
}
