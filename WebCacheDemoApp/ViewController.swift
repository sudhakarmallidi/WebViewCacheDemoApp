import UIKit
import WebKit

let httpsURL = "https://www.xyz.com.sg/personal/deposits/default.page"

// MARK: - View Controller
class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blue
        setupWebView()
        loadAirbnb()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(CacheSchemeHandler(), forURLScheme: DaasWebView.scheme)
        config.websiteDataStore = WKWebsiteDataStore.default()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }

    private func loadAirbnb() {
        let myAppURLString = httpsURL.replacingOccurrences(of: "https", with: DaasWebView.scheme)
        if let myAppURL = URL(string: myAppURLString) {
            let request = URLRequest(url: myAppURL)
            webView.load(request)
            print("🌐 Loading via custom scheme: \(myAppURLString)")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ loaded successfully")
    }
}
