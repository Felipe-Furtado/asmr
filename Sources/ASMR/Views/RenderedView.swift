import SwiftUI
import WebKit

/// Displays rendered Markdown HTML inside a WKWebView.
/// Read-only in v1. Inline editing is deferred to v2.
struct RenderedView: NSViewRepresentable {

    let html: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isTextInteractionEnabled = true  // allow text selection / copy

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Disable the web view's own right-click menu so we can provide a native one later
        webView.allowsMagnification = true
        webView.enclosingScrollView?.hasVerticalScroller = true

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Resolve the bundle's Resources directory as the base URL so that
        // relative paths (images, local CSS) work correctly.
        let baseURL = Bundle.module.resourceURL

        webView.loadHTMLString(html, baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        /// Open links in the default browser rather than navigating inside the WebView.
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
