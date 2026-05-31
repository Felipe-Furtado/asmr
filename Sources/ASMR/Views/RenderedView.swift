import SwiftUI
import WebKit

/// Displays rendered Markdown HTML inside a WKWebView.
/// Read-only in v1 (click to select text / copy works).
/// True inline editing (WYSIWYG) is deferred to v2.
struct RenderedView: NSViewRepresentable {

    let html: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isTextInteractionEnabled = true   // allow select & copy

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Use the bundle resource directory as the base URL so that relative
        // paths (styles.css, highlight.min.js) resolve correctly.
        let baseURL = Bundle.module.resourceURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        /// Intercept link taps — open in system browser, never navigate the WebView.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
