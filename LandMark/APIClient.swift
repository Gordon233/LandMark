
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
    var baseURL: String { "https://f620cf495fcd.ngrok-free.app" }
    var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true"
        ]
    }

    var url: URL? {
        URL(string: baseURL + path)
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
            throw NetworkError.invalidURL
        }

        let request = buildRequest(url: url, method: endpoint.method, headers: endpoint.headers)
        return try await performRequest(request)
    }

    // MARK: - POST/PUT/PATCH Request with Body
    func request<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = buildRequest(url: url, method: endpoint.method, headers: endpoint.headers)

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw NetworkError.encodingError(error)
        }

        return try await performRequest(request)
    }

    // MARK: - Private Helper Methods
    private func buildRequest(url: URL, method: HTTPMethod, headers: [String: String]) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.badStatusCode(0)
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.badStatusCode(httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                throw NetworkError.noData
            }

            return try decoder.decode(T.self, from: data)

        } catch let error as NetworkError {
            throw error
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        } catch {
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