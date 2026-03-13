import SwiftUI

struct ErrorListView: View {
    let errors: [DiscoveryError]

    var body: some View {
        List(errors) { error in
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.message)
                        .font(.body)
                    Text(error.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .accessibilityIdentifier("errorList.row")
        }
        .accessibilityIdentifier("errorList")
        .navigationTitle("Errors")
    }
}
