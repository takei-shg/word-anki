import Foundation

// MARK: - API Configuration

struct APIConfiguration {
    let baseURL: URL
    let timeout: TimeInterval
    let maxRetryAttempts: Int
    let retryDelay: TimeInterval
    
    static let development = APIConfiguration(
        baseURL: URL(string: "http://localhost:3000/api")!,
        timeout: 30.0,
        maxRetryAttempts: 3,
        retryDelay: 1.0
    )
    
    static let production = APIConfiguration(
        baseURL: URL(string: "https://api.vocabularyapp.com/api")!,
        timeout: 30.0,
        maxRetryAttempts: 3,
        retryDelay: 2.0
    )
}

// MARK: - API Service Implementation

class APIService: APIServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let configuration: APIConfiguration
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(configuration: APIConfiguration = .development, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        
        // Configure JSON encoder
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        
        // Configure JSON decoder
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - APIServiceProtocol Implementation
    
    func uploadTextSource(_ source: TextSource) async throws -> TextSource {
        let request = UploadTextRequest(from: source)
        let endpoint = "/text-sources"
        
        let response: TextSource = try await performRequest(
            endpoint: endpoint,
            method: .POST,
            body: request
        )
        
        return response
    }
    
    func fetchWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async throws -> [WordTest] {
        var endpoint = "/text-sources/\(sourceId.uuidString)/word-tests"
        
        if let difficulty = difficulty {
            endpoint += "/\(difficulty.rawValue)"
        }
        
        let response: [WordTest] = try await performRequest(
            endpoint: endpoint,
            method: .GET
        )
        
        return response
    }
    
    func syncProgress(_ progress: [UserProgress]) async throws {
        let request = SyncProgressRequest(progress: progress)
        let endpoint = "/sync/progress"
        
        let _: SyncProgressResponse = try await performRequest(
            endpoint: endpoint,
            method: .POST,
            body: request
        )
    }
    
    // MARK: - Additional API Methods
    
    func fetchTextSources() async throws -> [TextSource] {
        let endpoint = "/text-sources"
        
        let response: [TextSource] = try await performRequest(
            endpoint: endpoint,
            method: .GET
        )
        
        return response
    }
    
    func deleteTextSource(id: UUID) async throws {
        let endpoint = "/text-sources/\(id.uuidString)"
        
        let _: EmptyResponse = try await performRequest(
            endpoint: endpoint,
            method: .DELETE
        )
    }
    
    func fetchProcessingStatus(for sourceId: UUID) async throws -> ProcessingStatusResponse {
        let endpoint = "/text-sources/\(sourceId.uuidString)/status"
        
        let response: ProcessingStatusResponse = try await performRequest(
            endpoint: endpoint,
            method: .GET
        )
        
        return response
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil,
        queryParameters: [String: String]? = nil
    ) async throws -> U {
        
        var attempt = 0
        var lastError: Error?
        
        while attempt < configuration.maxRetryAttempts {
            do {
                return try await executeRequest(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    queryParameters: queryParameters
                )
            } catch {
                lastError = error
                attempt += 1
                
                // Don't retry for certain errors
                if !shouldRetry(error: error) {
                    throw error
                }
                
                if attempt < configuration.maxRetryAttempts {
                    try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIServiceError.maxRetriesExceeded
    }
    
    private func executeRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil,
        queryParameters: [String: String]? = nil
    ) async throws -> U {
        
        // Build URL
        var url = configuration.baseURL.appendingPathComponent(endpoint)
        
        if let queryParameters = queryParameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components?.url ?? url
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = configuration.timeout
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add body if present
        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                throw APIServiceError.encodingError(error)
            }
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        // Handle HTTP errors
        guard 200...299 ~= httpResponse.statusCode else {
            let apiError = try? jsonDecoder.decode(APIError.self, from: data)
            throw APIServiceError.httpError(httpResponse.statusCode, apiError)
        }
        
        // Handle empty response for certain methods
        if method == .DELETE || U.self == EmptyResponse.self {
            return EmptyResponse() as! U
        }
        
        // Decode response
        do {
            return try jsonDecoder.decode(U.self, from: data)
        } catch {
            throw APIServiceError.decodingError(error)
        }
    }
    
    private func shouldRetry(error: Error) -> Bool {
        switch error {
        case APIServiceError.httpError(let statusCode, _):
            // Retry on server errors (5xx) and some client errors
            return statusCode >= 500 || statusCode == 408 || statusCode == 429
        case APIServiceError.networkError:
            return true
        case URLError.timedOut, URLError.networkConnectionLost, URLError.notConnectedToInternet:
            return true
        default:
            return false
        }
    }
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Empty Response Model

struct EmptyResponse: Codable {
    init() {}
}

// MARK: - API Service Errors

enum APIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case httpError(Int, APIError?)
    case maxRetriesExceeded
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let apiError):
            if let apiError = apiError {
                return "HTTP \(statusCode): \(apiError.message)"
            } else {
                return "HTTP error \(statusCode)"
            }
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .noInternetConnection:
            return "No internet connection available"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .httpError(_, let apiError):
            return apiError?.failureReason
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Please check your internet connection and try again."
        case .httpError(let statusCode, let apiError):
            if let suggestion = apiError?.recoverySuggestion {
                return suggestion
            } else if statusCode >= 500 {
                return "The server is experiencing issues. Please try again later."
            } else {
                return "Please check your request and try again."
            }
        case .maxRetriesExceeded:
            return "The request failed after multiple attempts. Please try again later."
        default:
            return "Please try again."
        }
    }
}

// MARK: - Network Monitoring Extension

extension APIService {
    
    func checkNetworkConnectivity() async -> Bool {
        do {
            let url = configuration.baseURL.appendingPathComponent("/health")
            let request = URLRequest(url: url)
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}