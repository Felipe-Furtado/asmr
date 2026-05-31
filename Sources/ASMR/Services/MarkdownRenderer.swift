import Foundation
import Ink

/// Converts a Markdown string to a full HTML document ready to load into WKWebView.
///
/// Uses Ink — a lightweight, pure-Swift CommonMark + GFM parser.
/// No C library dependencies, no bridging headers, no network access.
///
/// Marked @MainActor because it is only ever called from SwiftUI views,
/// which always run on the main thread. This keeps Swift 6 strict concurrency happy.
@MainActor
final class MarkdownRenderer {

    static let shared = MarkdownRenderer()

    // MARK: - Private state

    private let template: String
    private var parser = MarkdownParser()

    // MARK: - Init

    private init() {
        if let url = Bundle.module.url(forResource: "template", withExtension: "html"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            template = contents
        } else {
            // Fallback: inline minimal template (should never be hit in a real build)
            template = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <link rel="stylesheet" href="styles.css">
            </head>
            <body><article class="markdown-body">{{CONTENT}}</article></body>
            </html>
            """
        }
    }

    // MARK: - Public API

    /// Render a Markdown string to a full, standalone HTML document.
    func render(_ markdown: String) -> String {
        let result = parser.parse(markdown)
        return template.replacingOccurrences(of: "{{CONTENT}}", with: result.html)
    }
}
