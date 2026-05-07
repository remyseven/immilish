import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebView()
            .ignoresSafeArea()
            .preferredColorScheme(.light)
    }
}

struct WebView: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Allow inline media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Allow local file access
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.backgroundColor = UIColor(red: 1.0, green: 0.992, blue: 0.969, alpha: 1.0)
        webView.isOpaque = false

        // Allow drag and drop for conversation buddy feature
        webView.scrollView.isScrollEnabled = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load the Immilish HTML app from the app bundle
        if let url = Bundle.main.url(forResource: "immilish-app", withExtension: "html") {
            let request = URLRequest(url: url)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation within the app
            if let url = navigationAction.request.url {
                let scheme = url.scheme ?? ""
                // Allow https calls to Anthropic API and fonts
                if scheme == "https" || scheme == "file" || scheme == "about" {
                    decisionHandler(.allow)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject viewport meta to ensure proper scaling
            let js = """
                var meta = document.querySelector('meta[name=viewport]');
                if (!meta) {
                    meta = document.createElement('meta');
                    meta.name = 'viewport';
                    document.head.appendChild(meta);
                }
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
