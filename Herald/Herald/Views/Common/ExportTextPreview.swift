import SwiftUI

struct ExportTextPreview: View {
    let title: String
    let text: String
    let json: String?

    @Environment(\.dismiss) private var dismiss
    @State private var format: ExportFormat = .text
    @State private var exportFileURL: URL?

    private enum ExportFormat: String, CaseIterable {
        case text = "Text"
        case json = "JSON"
    }

    init(title: String, text: String, json: String? = nil) {
        self.title = title
        self.text = text
        self.json = json
    }

    private var displayText: String {
        switch format {
        case .text: text
        case .json: json ?? text
        }
    }

    private var fileExtension: String {
        format == .json ? "json" : "txt"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(displayText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("export.preview")
            .task(id: format) {
                exportFileURL = writeExportFile()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if json != nil {
                    ToolbarItem(placement: .principal) {
                        Picker("Format", selection: $format) {
                            ForEach(ExportFormat.allCases, id: \.self) { fmt in
                                Text(fmt.rawValue).tag(fmt)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let exportFileURL {
                        ShareLink(
                            "Share",
                            item: exportFileURL,
                            preview: SharePreview(title)
                        )
                        .labelStyle(.iconOnly)
                    }
                }
            }
        }
    }

    private func writeExportFile() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: .now)

        let sanitizedTitle = title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        let fileName = "\(sanitizedTitle)_\(timestamp).\(fileExtension)"
        let exportDir = URL.cachesDirectory.appending(path: "exports", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        let fileURL = exportDir.appending(path: fileName)

        do {
            try displayText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
