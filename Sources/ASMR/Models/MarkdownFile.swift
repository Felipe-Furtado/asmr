import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// The `.md` / `.markdown` file type.
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}

/// The document model. A Markdown file is just a UTF-8 string.
/// `FileDocument` gives us open/save/save-as and dirty-state tracking for free
/// via SwiftUI's `DocumentGroup` scene.
struct MarkdownFile: FileDocument {

    // MARK: - FileDocument conformance

    static var readableContentTypes: [UTType] { [.markdown] }

    static var writableContentTypes: [UTType] { [.markdown] }

    // MARK: - Content

    var text: String

    // MARK: - Init

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    // MARK: - Write

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
