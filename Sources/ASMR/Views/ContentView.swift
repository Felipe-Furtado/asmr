import SwiftUI

/// The root view for an open document window.
/// Owns the rendered ↔ raw toggle and routes to the appropriate subview.
struct ContentView: View {

    @Binding var document: MarkdownFile
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewMode: ViewMode = .rendered
    @State private var renderedHTML: String = ""

    var body: some View {
        Group {
            switch viewMode {
            case .rendered:
                RenderedView(html: renderedHTML)
            case .raw:
                RawEditorView(text: $document.text)
            }
        }
        .frame(minWidth: 480, idealWidth: 760, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: toggle) {
                    Label(
                        viewMode == .rendered ? "Edit Source" : "Preview",
                        systemImage: viewMode == .rendered ? "pencil" : "eye"
                    )
                }
                .help(
                    viewMode == .rendered
                        ? "Switch to raw Markdown editor (⌘U)"
                        : "Switch to rendered preview (⌘U)"
                )
                .keyboardShortcut("u", modifiers: .command)
            }
        }
        .onAppear { render() }
        // Re-render when the document changes or the OS appearance flips
        .onChange(of: document.text)  { render() }
        .onChange(of: colorScheme)    { render() }
    }

    // MARK: - Private

    private func toggle() {
        if viewMode == .raw { render() }
        viewMode = viewMode == .rendered ? .raw : .rendered
    }

    private func render() {
        renderedHTML = MarkdownRenderer.shared.render(
            document.text,
            isDark: colorScheme == .dark
        )
    }
}

// MARK: - View mode

extension ContentView {
    enum ViewMode {
        case rendered
        case raw
    }
}
