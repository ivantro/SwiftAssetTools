import Foundation

/// API client for handling requests to the AssetLoader service
public class APIClient {
    /// Default base URL for the API
    public static let defaultBaseURL = "https://your-custom-api.com/api"
    
    /// Base URL for the API
    private let baseURL: String
    
    /// URL session for making requests
    private let urlSession: URLSession
    
    /// Initialize the API client with optional base URL
    /// - Parameters:
    ///   - baseURL: The base URL for the API. Defaults to the default server URL
    ///   - urlSession: The URL session to use for requests. Defaults to shared session
    public init(baseURL: String = APIClient.defaultBaseURL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }
    
    /// Fetch download information by ID
    /// - Parameter downloadId: The ID of the download to fetch
    /// - Returns: DownloadResponse containing the download information
    /// - Throws: APIError for various error conditions
    public func getDownload(downloadId: String) async throws -> DownloadResponse {
        guard !downloadId.isEmpty else {
            throw APIError.invalidDownloadId
        }
        
        let urlString = "\(baseURL)/downloads/\(downloadId)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let downloadResponse = try JSONDecoder().decode(DownloadResponse.self, from: data)
            return downloadResponse
            
        } catch let error as APIError {
            throw error
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(decodingError)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

/// Errors that can occur when using the API client
public enum APIError: Error, LocalizedError {
    case invalidDownloadId
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(DecodingError)
    
    public var errorDescription: String? {
        switch self {
        case .invalidDownloadId:
            return "Invalid download ID provided"
        case .invalidURL:
            return "Invalid URL constructed"
        case .invalidResponse:
            return "Invalid response received from server"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
} 
