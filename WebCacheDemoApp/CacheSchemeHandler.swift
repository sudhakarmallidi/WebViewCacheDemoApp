import Foundation
import WebKit
import Combine
import CryptoKit

struct DaasWebView {
    static let scheme: String = "x-file"
}
// MARK: - Cache Handler
class CacheSchemeHandler: NSObject, WKURLSchemeHandler {

    // MARK: - Properties
    private let cacheDirectory: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WebCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()

    // Optimized: Use a concurrent OperationQueue with ~8-12 max concurrent ops
    private lazy var urlSession: URLSession = {
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 16
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 16
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config, delegate: nil, delegateQueue: opQueue)
    }()

    // Use a concurrent queue for thread-safe access to dictionaries
    private let stateQueue = DispatchQueue(label: "com.cachehandler.state", attributes: .concurrent)

    // Use ObjectIdentifier for protocol-based keys
    private var activeCancellables = [ObjectIdentifier: AnyCancellable]()

    // Deduplication: Track ongoing downloads to avoid duplicate requests
    // (No change needed here, since WKURLSchemeTask is not a key)
    private var ongoingDownloads = [String: [(task: WKURLSchemeTask, cachePath: URL?)]]()

    private let downloadService = DownloadService()

    // Concurrent queue for I/O operations (reads are concurrent, writes use .barrier)
    private let ioQueue = DispatchQueue(label: "com.cachehandler.io", qos: .userInitiated, attributes: .concurrent)

    // MARK: - WKURLSchemeHandler Methods

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }

        let cacheFileName = generateCacheFileName(from: url)
        let cachePath = cacheDirectory.appendingPathComponent(cacheFileName)
        let shouldCache = shouldCacheResource(fileName: cacheFileName, url: url)
        let finalCachePath = shouldCache ? cachePath : nil

        if shouldCache {
            // Check cache first, non-blocking
            ioQueue.async { [weak self] in
                guard let self = self else { return }
                if FileManager.default.fileExists(atPath: cachePath.path),
                   let data = try? Data(contentsOf: cachePath) {
                    print("📦 Cache hit: Serving from cache '\(cacheFileName)' at path \(cachePath.path)")
                    let mimeType = self.mimeType(for: cacheFileName)
                    let response = URLResponse(
                        url: url,
                        mimeType: mimeType,
                        expectedContentLength: data.count,
                        textEncodingName: "utf-8"
                    )
                    // Only response must go to main thread
                    DispatchQueue.main.async {
                        urlSchemeTask.didReceive(response)
                        urlSchemeTask.didReceive(data)
                        urlSchemeTask.didFinish()
                    }
                } else {
                    print("🔎 Cache miss: '\(cacheFileName)' not in cache at \(cachePath.path), will download.")
                    self.startDownload(url: url, urlSchemeTask: urlSchemeTask, cachePath: finalCachePath)
                }
            }
        } else {
            print("⏩ Resource '\(cacheFileName)' is not cacheable, downloading directly.")
            startDownload(url: url, urlSchemeTask: urlSchemeTask, cachePath: nil)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let taskID = ObjectIdentifier(urlSchemeTask)
        stateQueue.sync {
            activeCancellables[taskID]?.cancel()
        }
        stateQueue.async(flags: .barrier) {
            self.activeCancellables.removeValue(forKey: taskID)
        }
    }

    // MARK: - Download Logic

    private func startDownload(url: URL, urlSchemeTask: WKURLSchemeTask, cachePath: URL?) {
        // Convert custom scheme → https
        let actualURLString = url.absoluteString.replacingOccurrences(of: DaasWebView.scheme, with: "https")
        guard let actualURL = URL(string: actualURLString) else {
            print("❌ Invalid URL for download: \(actualURLString)")
            urlSchemeTask.didFailWithError(NSError(domain: "InvalidURL", code: -1, userInfo: nil))
            return
        }

        let urlKey = actualURL.absoluteString

        // Deduplicate downloads for the same URL
        var shouldStart = false
        stateQueue.sync(flags: .barrier) {
            if var waiters = ongoingDownloads[urlKey] {
                waiters.append((task: urlSchemeTask, cachePath: cachePath))
                ongoingDownloads[urlKey] = waiters
            } else {
                ongoingDownloads[urlKey] = [(task: urlSchemeTask, cachePath: cachePath)]
                shouldStart = true
            }
        }
        if !shouldStart {
            // Another request is already downloading this URL. Just wait.
            print("⏳ Download already in progress for \(urlKey), waiting for completion.")
            return
        }

        // Start actual download
        var request = URLRequest(url: actualURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let taskID = ObjectIdentifier(urlSchemeTask)
        print("🌐 Starting download for \(actualURL)")
        let cancellable = downloadService
            .fetch(request: request, session: urlSession)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                var waitingTasks: [(task: WKURLSchemeTask, cachePath: URL?)] = []
                self.stateQueue.sync(flags: .barrier) {
                    waitingTasks = self.ongoingDownloads[urlKey] ?? []
                    self.ongoingDownloads.removeValue(forKey: urlKey)
                }
                switch completion {
                case .failure(let error):
                    print("❗️ Download failed for \(actualURL): \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        for (task, _) in waitingTasks {
                            task.didFailWithError(error)
                        }
                    }
                case .finished:
                    break
                }
                self.stateQueue.async(flags: .barrier) {
                    self.activeCancellables.removeValue(forKey: taskID)
                }
            }, receiveValue: { [weak self] data, response in
                guard let self = self else { return }
                var waitingTasks: [(task: WKURLSchemeTask, cachePath: URL?)] = []
                self.stateQueue.sync(flags: .barrier) {
                    waitingTasks = self.ongoingDownloads[urlKey] ?? []
                }
                if let cachePath = cachePath {
                    self.ioQueue.async(flags: .barrier) {
                        do {
                            try data.write(to: cachePath, options: .atomic)
                            print("✅ Cached '\(cachePath.lastPathComponent)' at \(cachePath.path)")
                        } catch {
                            print("❗️ Failed to write to cache '\(cachePath.lastPathComponent)': \(error.localizedDescription)")
                        }
                    }
                }
                print("⬇️ Download completed for \(actualURL): \(data.count) bytes")
                DispatchQueue.main.async {
                    for (task, _) in waitingTasks {
                        task.didReceive(response)
                        task.didReceive(data)
                        task.didFinish()
                    }
                }
            })

        stateQueue.async(flags: .barrier) {
            self.activeCancellables[taskID] = cancellable
        }
    }

    // MARK: - Utility Methods

	private func generateCacheFileName(from url: URL) -> String {
		let urlString = url.absoluteString
		let digest = Insecure.MD5.hash(data: Data(urlString.utf8))
		let md5 = digest.map { String(format: "%02hhx", $0) }.joined()
		let ext = (url.lastPathComponent as NSString).pathExtension
		return ext.isEmpty ? md5 : "\(md5).\(ext)"
	}

    private func shouldCacheResource(fileName: String, url: URL) -> Bool {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let shouldCacheExtensions = ["js", "css", "woff", "woff2", "ttf", "eot", "png", "jpg", "jpeg", "gif", "svg", "json"]
        if shouldCacheExtensions.contains(ext) { return true }
        let path = url.path.lowercased()
        if path.contains("/static/") || path.contains("/assets/") ||
            path.contains("/build/") || path.contains("/dist/") ||
            path.contains("/public/") { return true }
        if ext == "html" || ext == "htm" || fileName == "index" { return false }
        let resourcePatterns = ["chunk", "bundle", "vendor", "main"]
        for pattern in resourcePatterns {
            if fileName.lowercased().contains(pattern) { return true }
        }
        return false
    }

    private func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "js": return "application/javascript"
        case "css": return "text/css"
        case "html", "htm": return "text/html"
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "eot": return "application/vnd.ms-fontobject"
        default: return "application/octet-stream"
        }
    }
}

