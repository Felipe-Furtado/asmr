import Foundation
import Ink

/// Converts a Markdown string to a full HTML document ready to load into WKWebView.
///
/// The theme (light/dark) is baked into the HTML at render time via a class on
/// the <html> element. This is more reliable than relying on WKWebView to
/// correctly report `prefers-color-scheme` — WebKit evaluates that at page-load
/// time and its timing inside NSViewRepresentable is unpredictable.
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
            template = """
            <!DOCTYPE html>
            <html class="{{THEME}}">
            <head><meta charset="utf-8">
            <link rel="stylesheet" href="styles.css">
            </head>
            <body><article class="markdown-body">{{CONTENT}}</article></body>
            </html>
            """
        }
    }

    // MARK: - Public API

    /// Render Markdown to a full HTML document.
    /// - Parameters:
    ///   - markdown: The raw Markdown source string.
    ///   - isDark: Pass `true` when the OS is in dark mode. The theme class is
    ///     injected directly into the `<html>` element so CSS selectors like
    ///     `html.dark { }` apply immediately on first paint.
    func render(_ markdown: String, isDark: Bool) -> String {
        let result = parser.parse(markdown)
        return template
            .replacingOccurrences(of: "{{THEME}}",   with: isDark ? "dark" : "light")
            .replacingOccurrences(of: "{{CONTENT}}", with: result.html)
    }
}
