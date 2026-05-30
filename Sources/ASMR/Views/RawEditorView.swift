import SwiftUI

/// A plain-text Markdown editor using SwiftUI's TextEditor.
/// Bound directly to the document's text string — mutations flow back
/// through the Binding and trigger dirty-state tracking automatically.
struct RawEditorView: View {

    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.custom("SF Mono", size: 14).monospaced())
            .lineSpacing(4)
            .padding(16)
            .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    RawEditorView(text: .constant("""
    # Hello, ASMR

    This is the **raw** Markdown source.

    - Item one
    - Item two

    ```swift
    let x = 42
    ```
    """))
    .frame(width: 720, height: 500)
}
