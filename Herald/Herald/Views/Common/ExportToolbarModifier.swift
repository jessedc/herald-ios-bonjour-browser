import SwiftUI

private struct ExportSnapshot: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let json: String?
}

struct ExportToolbarModifier: ViewModifier {
    let title: String
    let textProvider: () -> String
    let jsonProvider: (() -> String)?

    @State private var exportSnapshot: ExportSnapshot?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export", systemImage: "square.and.arrow.up") {
                        exportSnapshot = ExportSnapshot(
                            title: title,
                            text: textProvider(),
                            json: jsonProvider?()
                        )
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("export.button")
                }
            }
            .fullScreenCover(item: $exportSnapshot) { snapshot in
                ExportTextPreview(
                    title: snapshot.title,
                    text: snapshot.text,
                    json: snapshot.json
                )
                .accessibilityIdentifier("export.preview")
            }
    }
}

extension View {
    func exportable(title: String, text: @escaping () -> String) -> some View {
        modifier(ExportToolbarModifier(title: title, textProvider: text, jsonProvider: nil))
    }

    func exportable(title: String, text: @escaping () -> String, json: @escaping () -> String) -> some View {
        modifier(ExportToolbarModifier(title: title, textProvider: text, jsonProvider: json))
    }
}
