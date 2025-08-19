
import Foundation

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case noData
    case badStatusCode(Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Endpoint Protocol
protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
}

// MARK: - Default Endpoint Implementation
extension APIEndpoint {
    var baseURL: String { "https://e2f5f5319d36.ngrok-free.app" }
    var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true"
        ]
    }

    var url: URL? {
        let fullURL = baseURL + path
        print("🌐 [APIClient] Creating URL: \(fullURL)")

        guard let url = URL(string: fullURL) else {
            print("❌ [APIClient] Failed to create URL from string: \(fullURL)")
            return nil
        }

        print("✅ [APIClient] URL created successfully")
        print("   - Host: \(url.host ?? "nil")")
        print("   - Port: \(url.port?.description ?? "nil")")
        print("   - Path: \(url.path)")
        print("   - Scheme: \(url.scheme ?? "nil")")

        return url
    }
}

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response
}

// MARK: - Modern API Client
final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init(session: URLSession = .shared) {
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        // Configure encoders/decoders if needed
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - GET Request
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = endpoint.url else {
            print("❌ [APIClient] Invalid URL for endpoint: \(endpoint.path)")
            throw NetworkError.invalidURL
        }

        print("📤 [APIClient] GET Request to: \(url)")
        let request = buildRequest(url: url, method: endpoint.method, headers: endpoint.headers)
        return try await performRequest(request)
    }

    // MARK: - POST/PUT/PATCH Request with Body
    func request<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        guard let url = endpoint.url else {
            print("❌ [APIClient] Invalid URL for endpoint: \(endpoint.path)")
            throw NetworkError.invalidURL
        }

        print("📤 [APIClient] \(endpoint.method.rawValue) Request to: \(url)")
        var request = buildRequest(url: url, method: endpoint.method, headers: endpoint.headers)

        do {
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData
            if let bodyString = String(data: bodyData, encoding: .utf8) {
                print("📦 [APIClient] Request body: \(bodyString)")
            }
        } catch {
            print("❌ [APIClient] Encoding error: \(error)")
            throw NetworkError.encodingError(error)
        }

        return try await performRequest(request)
    }

    // MARK: - Private Helper Methods
    private func buildRequest(url: URL, method: HTTPMethod, headers: [String: String]) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30.0

        print("🔧 [APIClient] Building request:")
        print("   Method: \(method.rawValue)")
        print("   URL: \(url)")
        print("   Headers:")

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
            print("     \(key): \(value)")
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        print("🚀 [APIClient] Performing request...")

        // Add additional debugging for the request
        if let url = request.url {
            print("🔍 [APIClient] Request URL components:")
            print("   - Full URL: \(url.absoluteString)")
            print("   - Host: \(url.host ?? "nil")")
            print("   - Port: \(url.port?.description ?? "default")")
        }

        do {
            let (data, response) = try await session.data(for: request)

            print("📥 [APIClient] Received response")

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [APIClient] Invalid HTTP response")
                throw NetworkError.badStatusCode(0)
            }

            print("📊 [APIClient] Status code: \(httpResponse.statusCode)")
            print("📋 [APIClient] Response headers: \(httpResponse.allHeaderFields)")

            guard 200...299 ~= httpResponse.statusCode else {
                print("❌ [APIClient] Bad status code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 [APIClient] Error response body: \(responseString)")
                }
                throw NetworkError.badStatusCode(httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                print("❌ [APIClient] No data received")
                throw NetworkError.noData
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [APIClient] Response body: \(responseString)")
            }

            print("🔄 [APIClient] Decoding response...")
            let result = try decoder.decode(T.self, from: data)
            print("✅ [APIClient] Successfully decoded response")
            return result

        } catch let error as NetworkError {
            print("❌ [APIClient] NetworkError: \(error.localizedDescription)")
            throw error
        } catch let decodingError as DecodingError {
            print("❌ [APIClient] DecodingError: \(decodingError)")
            throw NetworkError.decodingError(decodingError)
        } catch {
            print("❌ [APIClient] General error: \(error.localizedDescription)")
            print("❌ [APIClient] Error type: \(type(of: error))")
            throw NetworkError.networkError(error)
        }
    }
}



// MARK: - Error Extensions
extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .noData:
            return "No data received from server"
        case .badStatusCode(let statusCode):
            return "Server returned status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}