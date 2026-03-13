import SwiftUI

struct ErrorRow: View {
    let message: String
    var detail: String?
    var retryAction: (() -> Void)?

    var body: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message).font(.headline)
                    if let detail {
                        Text(detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            if let retryAction {
                Button("Retry", action: retryAction)
            }
        }
    }
}
