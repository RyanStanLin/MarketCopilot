import Foundation

final class OriginRedirectDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        let original = task.originalRequest?.url
        let allowed = request.url?.scheme == "https" && request.url?.host == original?.host && request.url?.port == original?.port
        completionHandler(allowed ? request : nil)
    }
}
