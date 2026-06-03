import SwiftUI
import WebKit

/// Displays rendered Markdown HTML inside a WKWebView.
/// Read-only in v1 (text selection / copy works).
/// True inline WYSIWYG editing is deferred to v2.
struct RenderedView: NSViewRepresentable {

    let html: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isTextInteractionEnabled = true   // allow select & copy

        // Belt-and-suspenders: force white-space on pre/code via JS after DOM is built.
        // Fires at inline-style specificity so it cannot be overridden by UA stylesheets
        // or any cascade quirk inside WKWebView.
        let wsScript = WKUserScript(
            source: """
            document.querySelectorAll('pre, pre code').forEach(function(el) {
                el.style.whiteSpace = 'pre-wrap';
                el.style.overflowWrap = 'anywhere';
                el.style.wordBreak = 'normal';
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(wsScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Prevent the white flash that appears before the HTML finishes loading.
        // The page background colour (from our inlined CSS) takes over immediately.
        webView.setValue(false, forKey: "drawsBackground")

        webView.allowsMagnification = true
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // The html string is fully self-contained — CSS is inlined, theme class
        // is already stamped on <html>. Pass nil as baseURL; there are no
        // external resources to resolve.
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        /// Open links in the system browser; never navigate the WebView itself.
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
