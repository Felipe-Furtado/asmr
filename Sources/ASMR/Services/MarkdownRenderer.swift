import Foundation

/// Converts a Markdown string to a full HTML document ready to load into WKWebView.
///
/// In v1 this uses a simple regex-free approach with Foundation to avoid adding
/// a C library dependency before the project is fully set up. Replace the
/// `parseMarkdown(_:)` body with a cmark-gfm call once the SPM dependency is wired in.
///
/// The renderer is a singleton because loading the HTML template from disk is
/// slightly expensive and we want to do it once.
final class MarkdownRenderer {

    static let shared = MarkdownRenderer()

    // MARK: - Private state

    private let template: String

    // MARK: - Init

    private init() {
        // Load the HTML template from the app bundle.
        if let url = Bundle.module.url(forResource: "template", withExtension: "html"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            template = contents
        } else {
            // Fallback minimal template — should never happen in a real build.
            template = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"></head>
            <body>{{CONTENT}}</body>
            </html>
            """
        }
    }

    // MARK: - Public API

    /// Render Markdown text to a full HTML document string.
    func render(_ markdown: String) -> String {
        let fragment = parseMarkdown(markdown)
        return template.replacingOccurrences(of: "{{CONTENT}}", with: fragment)
    }

    // MARK: - Markdown → HTML

    /// Converts Markdown to an HTML fragment.
    ///
    /// TODO: Replace this stub with a real cmark-gfm call:
    ///
    ///     import cmark_gfm
    ///     let node = cmark_gfm_parse_document(markdown, markdown.utf8.count, CMARK_OPT_DEFAULT, ...)
    ///     let html = String(cString: cmark_render_html(node, CMARK_OPT_DEFAULT, nil))
    ///     cmark_node_free(node)
    ///
    /// For now, emit an escaped pre-block so we can verify the WKWebView pipeline
    /// end-to-end before the parser dependency is in place.
    private func parseMarkdown(_ markdown: String) -> String {
        // Placeholder: wrap raw text in a <pre> so it's visible in the WebView.
        // Replace this with cmark-gfm output.
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return "<pre style='font-family:monospace;white-space:pre-wrap'>\(escaped)</pre>"
    }
}
