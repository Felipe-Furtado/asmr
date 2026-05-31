import Foundation
import Ink

/// Converts a Markdown string to a fully self-contained HTML document for WKWebView.
///
/// ## Why CSS is inlined
/// `WKWebView.loadHTMLString(_:baseURL:)` does not reliably load relative
/// `file://` resources (stylesheets, scripts) even when a bundle base URL is
/// provided — WebKit's security model silently blocks them in many configurations.
/// Rather than fight this, we load `styles.css` from the bundle once at init
/// time and inline it directly into every generated HTML page. The page becomes
/// a single self-contained string with no external dependencies.
///
/// ## Why theme is baked in, not via prefers-color-scheme
/// `@media (prefers-color-scheme: dark)` requires WKWebView to receive the
/// correct NSAppearance, which is not reliably propagated from SwiftUI's
/// NSViewRepresentable — especially inside a DocumentGroup window. Instead,
/// the caller passes `isDark` and we stamp `class="dark"` or `class="light"`
/// onto the `<html>` element before the page loads. CSS uses `html.dark { }`
/// selectors that fire on first paint with no timing dependency.
@MainActor
final class MarkdownRenderer {

    static let shared = MarkdownRenderer()

    // MARK: - Private state

    private let template: String
    private let css: String
    private var parser = MarkdownParser()

    // MARK: - Init

    private init() {
        // Load template
        if let url = Bundle.module.url(forResource: "template", withExtension: "html"),
           let t = try? String(contentsOf: url, encoding: .utf8) {
            template = t
        } else {
            template = """
            <!DOCTYPE html>
            <html class="{{THEME}}">
            <head><meta charset="utf-8"><style>{{STYLES}}</style></head>
            <body><article class="markdown-body">{{CONTENT}}</article></body>
            </html>
            """
        }

        // Load CSS — if missing fall back to bare minimum so page is readable
        if let url = Bundle.module.url(forResource: "styles", withExtension: "css"),
           let c = try? String(contentsOf: url, encoding: .utf8) {
            css = c
        } else {
            css = """
            html.dark { background:#1e1e1e; color:#e8e8e8 }
            html.light { background:#ffffff; color:#1a1a1a }
            body { font-family: -apple-system, sans-serif; line-height:1.6;
                   max-width:680px; margin:0 auto; padding:2rem }
            """
        }
    }

    // MARK: - Public API

    /// Render Markdown to a fully self-contained HTML document string.
    ///
    /// - Parameters:
    ///   - markdown: The raw Markdown source.
    ///   - isDark:   Pass `true` when the OS is in dark mode. The theme class
    ///               is injected onto `<html>` so CSS `html.dark { }` rules
    ///               apply on the very first paint.
    func render(_ markdown: String, isDark: Bool) -> String {
        let result = parser.parse(markdown)
        return template
            .replacingOccurrences(of: "{{THEME}}",   with: isDark ? "dark" : "light")
            .replacingOccurrences(of: "{{STYLES}}",  with: css)
            .replacingOccurrences(of: "{{CONTENT}}", with: result.html)
    }
}
