import SwiftUI

/// The root view for an open document window.
/// Owns the view-mode toggle and routes to either the rendered or raw editor.
struct ContentView: View {

    @Binding var document: MarkdownFile

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    toggle()
                } label: {
                    Label(
                        viewMode == .rendered ? "Edit Source" : "Preview",
                        systemImage: viewMode == .rendered ? "pencil" : "eye"
                    )
                }
                .help(viewMode == .rendered ? "Switch to raw Markdown editor (⌘U)" : "Switch to rendered preview (⌘U)")
                .keyboardShortcut("u", modifiers: .command)
            }
        }
        .onAppear {
            renderIfNeeded()
        }
        .onChange(of: document.text) {
            // Re-render whenever text changes while in rendered mode
            if viewMode == .rendered {
                renderIfNeeded()
            }
        }
    }

    // MARK: - Private

    private func toggle() {
        switch viewMode {
        case .rendered:
            viewMode = .raw
        case .raw:
            renderIfNeeded()
            viewMode = .rendered
        }
    }

    private func renderIfNeeded() {
        renderedHTML = MarkdownRenderer.shared.render(document.text)
    }
}

// MARK: - View mode

extension ContentView {
    enum ViewMode {
        case rendered
        case raw
    }
}

// MARK: - Preview

#Preview {
    ContentView(
        document: .constant(
            MarkdownFile(text: """
            # Hello, ASMR

            This is a **preview** of the rendered view.

            - Item one
            - Item two
            - Item three

            ```swift
            let greeting = "Hello, world!"
            print(greeting)
            ```
            """)
        )
    )
}
