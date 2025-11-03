import Foundation
import WebKit

enum DownloadError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case fileSystemError
    case invalidURLComponents
    case fileNotFound
    case unsupportedFileType
}

enum FileType: String, CaseIterable {
    case js = "js"
    case css = "css"
    case svg = "svg"
    case html = "html"
    case png = "png"
    case jpg = "jpg"
    case jpeg = "jpeg"
    case gif = "gif"
    case json = "json"
    case txt = "txt"
    
    var mimeType: String {
        switch self {
        case .js: return "application/javascript"
        case .css: return "text/css"
        case .svg: return "image/svg+xml"
        case .html: return "text/html"
        case .png: return "image/png"
        case .jpg, .jpeg: return "image/jpeg"
        case .gif: return "image/gif"
        case .json: return "application/json"
        case .txt: return "text/plain"
        }
    }
    
    static func fromFileExtension(_ ext: String) -> FileType? {
        return FileType.allCases.first { $0.rawValue == ext.lowercased() }
    }
}

class FileDownloader {
    static let shared = FileDownloader()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let downloadQueue = DispatchQueue(label: "com.filedownloader.queue", attributes: .concurrent)
    private var activeDownloads: [String: URLSessionDownloadTask] = [:]
    private let urlSession: URLSession
    
    private init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDir.appendingPathComponent("DownloadedFiles")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    func downloadFile(
        from urlString: String,
        fileType: FileType,
        ignoreQueryParams: Bool = true,
        completion: @escaping (Result<URL, DownloadError>) -> Void
    ) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            let filename = self.generateUniqueFilename(
                from: urlString,
                fileType: fileType,
                ignoreQueryParams: ignoreQueryParams
            )
            let localURL = self.cacheDirectory.appendingPathComponent(filename)
            
            if self.fileManager.fileExists(atPath: localURL.path) {
                DispatchQueue.main.async {
                    completion(.success(localURL))
                }
                return
            }
            
            if self.activeDownloads[filename] != nil {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(NSError(domain: "Download already in progress", code: 0))))
                }
                return
            }
            
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidURL))
                }
                return
            }
            
            let downloadTask = self.urlSession.downloadTask(with: url) { [weak self] tempURL, response, error in
                guard let self = self else { return }
                
                self.downloadQueue.async(flags: .barrier) {
                    self.activeDownloads.removeValue(forKey: filename)
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(.networkError(error)))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                do {
                    try self.fileManager.moveItem(at: tempURL, to: localURL)
                    
                    if self.fileManager.fileExists(atPath: localURL.path) {
                        DispatchQueue.main.async {
                            completion(.success(localURL))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(.fileSystemError))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(.fileSystemError))
                    }
                }
            }
            
            self.downloadQueue.async(flags: .barrier) {
                self.activeDownloads[filename] = downloadTask
            }
            
            downloadTask.resume()
        }
    }
    
    func clearAllCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    func getCachedFileURL(
        for urlString: String,
        fileType: FileType,
        ignoreQueryParams: Bool = true
    ) -> URL? {
        let filename = generateUniqueFilename(
            from: urlString,
            fileType: fileType,
            ignoreQueryParams: ignoreQueryParams
        )
        let localURL = cacheDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    func getCachedFileData(
        for urlString: String,
        fileType: FileType,
        ignoreQueryParams: Bool = true
    ) -> Data? {
        guard let localURL = getCachedFileURL(for: urlString, fileType: fileType, ignoreQueryParams: ignoreQueryParams) else {
            return nil
        }
        return try? Data(contentsOf: localURL)
    }
    
    func isFileCached(
        for urlString: String,
        fileType: FileType,
        ignoreQueryParams: Bool = true
    ) -> Bool {
        let filename = generateUniqueFilename(
            from: urlString,
            fileType: fileType,
            ignoreQueryParams: ignoreQueryParams
        )
        let localURL = cacheDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: localURL.path)
    }
    
    // MARK: - Scheme Handler Support
    
    func handleSchemeRequest(for url: URL, completion: @escaping (Data?, String?, Error?) -> Void) {
        let urlString = url.absoluteString
        let fileExtension = url.pathExtension.lowercased()
        
        guard let fileType = FileType.fromFileExtension(fileExtension) else {
            completion(nil, nil, DownloadError.unsupportedFileType)
            return
        }
        
        // Check if file is already cached
        if let cachedData = getCachedFileData(for: urlString, fileType: fileType) {
            completion(cachedData, fileType.mimeType, nil)
            return
        }
        
        // Download and cache the file
        downloadFile(from: urlString, fileType: fileType) { result in
            switch result {
            case .success(let localURL):
                do {
                    let data = try Data(contentsOf: localURL)
                    completion(data, fileType.mimeType, nil)
                } catch {
                    completion(nil, nil, error)
                }
            case .failure(let error):
                completion(nil, nil, error)
            }
        }
    }
    
    func preloadResources(_ urls: [String], completion: (([String: Result<URL, DownloadError>]) -> Void)? = nil) {
        let dispatchGroup = DispatchGroup()
        var results: [String: Result<URL, DownloadError>] = [:]
        let resultsQueue = DispatchQueue(label: "com.filedownloader.results")
        
        for urlString in urls {
            guard let fileType = FileType.fromFileExtension(URL(string: urlString)?.pathExtension ?? "") else {
                continue
            }
            
            dispatchGroup.enter()
            
            downloadFile(from: urlString, fileType: fileType) { result in
                resultsQueue.async {
                    results[urlString] = result
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion?(results)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateUniqueFilename(
        from urlString: String,
        fileType: FileType,
        ignoreQueryParams: Bool = true
    ) -> String {
        let normalizedURL = normalizeURL(urlString, ignoreQueryParams: ignoreQueryParams) ?? urlString
        let md5 = normalizedURL.md5Hash()
        return "\(md5).\(fileType.rawValue)"
    }
    
    private func normalizeURL(_ urlString: String, ignoreQueryParams: Bool) -> String? {
        guard let url = URL(string: urlString),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        if ignoreQueryParams {
            components.query = nil
            components.fragment = nil
        } else if let queryItems = components.queryItems, queryItems.count > 0 {
            let sortedQueryItems = queryItems.sorted { $0.name < $1.name }
            components.queryItems = sortedQueryItems
        }
        
        return components.url?.absoluteString
    }
}

// MARK: - WKURLSchemeHandler Implementation

class DownloaderSchemeHandler: NSObject, WKURLSchemeHandler {
    private let downloader = FileDownloader.shared
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            let error = NSError(domain: "DownloaderSchemeHandler", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            urlSchemeTask.didFailWithError(error)
            return
        }
        
        downloader.handleSchemeRequest(for: url) { data, mimeType, error in
            if let error = error {
                urlSchemeTask.didFailWithError(error)
                return
            }
            
            guard let data = data, let mimeType = mimeType else {
                let error = NSError(domain: "DownloaderSchemeHandler", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
                urlSchemeTask.didFailWithError(error)
                return
            }
            
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": mimeType,
                    "Content-Length": "\(data.count)",
                    "Cache-Control": "public, max-age=31536000"
                ]
            )!
            
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // We could implement cancellation here if needed
        // Currently, the downloader doesn't support cancellation
    }
}

// MARK: - WKWebView Configuration Extension

extension WKWebViewConfiguration {
    static func withDownloaderSchemeHandler(scheme: String = "downloader") -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        let schemeHandler = DownloaderSchemeHandler()
        
        config.setURLSchemeHandler(schemeHandler, forURLScheme: scheme)
        
        return config
    }
}

// MARK: - WebView Manager

class WebViewManager: NSObject, WKNavigationDelegate {
    private let scheme: String
    private var webView: WKWebView?
    
    init(scheme: String = "downloader") {
        self.scheme = scheme
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration.withDownloaderSchemeHandler(scheme: scheme)
        
        // Additional configuration
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self
    }
    
    func loadHTMLString(_ htmlString: String, baseURL: URL? = nil) {
        webView?.loadHTMLString(htmlString, baseURL: baseURL)
    }
    
    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    func loadLocalContentWithRemoteResources(htmlContent: String, resourceURLs: [String]) {
        // Preload resources
        FileDownloader.shared.preloadResources(resourceURLs) { [weak self] results in
            print("Preloading completed with \(results.count) resources")
            
            // Convert remote URLs to downloader scheme URLs in HTML
            let modifiedHTML = self?.replaceURLsInHTML(htmlContent, withScheme: self?.scheme ?? "downloader") ?? htmlContent
            
            DispatchQueue.main.async {
                self?.loadHTMLString(modifiedHTML)
            }
        }
    }
    
    private func replaceURLsInHTML(_ html: String, withScheme scheme: String) -> String {
        var modifiedHTML = html
        
        // Simple regex to replace src and href attributes
        let patterns = [
            "src=\"(https?:[^\"]+)\"",
            "href=\"(https?:[^\"]+)\"",
            "url\\((https?:[^)]+)\\)"
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let matches = regex.matches(in: modifiedHTML, options: [], range: NSRange(location: 0, length: modifiedHTML.utf16.count))
                
                for match in matches.reversed() {
                    guard let range = Range(match.range(at: 1), in: modifiedHTML) else { continue }
                    let originalURL = String(modifiedHTML[range])
                    let downloaderURL = originalURL.replacingOccurrences(of: "https?:", with: "\(scheme):", options: .regularExpression)
                    modifiedHTML = modifiedHTML.replacingCharacters(in: range, with: downloaderURL)
                }
            } catch {
                print("Regex error: \(error)")
            }
        }
        
        return modifiedHTML
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Handle navigation decisions if needed
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView loading error: \(error)")
    }
    
    // MARK: - Public Interface
    
    func getWebView() -> WKWebView? {
        return webView
    }
    
    func clearCache() {
        try? FileDownloader.shared.clearAllCache()
    }
}

// MARK: - String Extension for MD5
extension String {
    func md5Hash() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        data.withUnsafeBytes { bytes in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

import CommonCrypto


// Usage
// Example in a ViewController
class WebViewController: UIViewController {
    
    private var webViewManager: WebViewManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadContent()
    }
    
    private func setupWebView() {
        webViewManager = WebViewManager(scheme: "cached")
        
        guard let webView = webViewManager.getWebView() else { return }
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadContent() {
        // Example 1: Load HTML with remote resources
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <link rel="stylesheet" href="https://cdn.example.com/styles.css?v=1.0.0">
        </head>
        <body>
            <h1>Hello World</h1>
            <img src="https://example.com/logo.svg" alt="Logo">
            <script src="https://cdn.example.com/app.js?timestamp=123456"></script>
        </body>
        </html>
        """
        
        let resourceURLs = [
            "https://cdn.example.com/styles.css?v=1.0.0",
            "https://example.com/logo.svg",
            "https://cdn.example.com/app.js?timestamp=123456"
        ]
        
        webViewManager.loadLocalContentWithRemoteResources(
            htmlContent: htmlString,
            resourceURLs: resourceURLs
        )
    }
    
    private func loadExternalURL() {
        // Example 2: Load external URL (resources will be cached automatically)
        if let url = URL(string: "https://example.com") {
            webViewManager.loadURL(url)
        }
    }
}

// Example of direct scheme handler usage
class CustomWebViewSetup {
    func createCustomWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let schemeHandler = DownloaderSchemeHandler()
        
        // Register for multiple schemes if needed
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "cached")
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "download")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }
    
    func loadCachedContent(webView: WKWebView) {
        let html = """
        <html>
            <body>
                <img src="cached://cdn.example.com/image.png" />
                <script src="cached://cdn.example.com/script.js"></script>
            </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// Example of preloading resources
class ResourcePreloader {
    func preloadCommonResources() {
        let commonResources = [
            "https://cdn.example.com/framework.js",
            "https://cdn.example.com/styles.css",
            "https://cdn.example.com/icons.svg",
            "https://cdn.example.com/logo.png"
        ]
        
        FileDownloader.shared.preloadResources(commonResources) { results in
            for (url, result) in results {
                switch result {
                case .success(let localURL):
                    print("Successfully preloaded: \(url) -> \(localURL)")
                case .failure(let error):
                    print("Failed to preload \(url): \(error)")
                }
            }
        }
    }
}
