import Foundation

/*
 Usage:
 // Using the main AssetLoader class
 let assetLoader = AssetLoader()
 let download = try await assetLoader.loadDownload(downloadId: "download.id")
 print("Assets: \(download.assets)")

 // Or using the API client directly
 let apiClient = APIClient()
 let response = try await apiClient.getDownload(downloadId: "download.id")

 // With custom base URL
 let customAssetLoader = AssetLoader(baseURL: "https://your-custom-api.com/api")
 */


/// Main AssetLoader class that provides a convenient interface for downloading and managing assets
public class AssetLoader {
    /// API client for making requests
    private let apiClient: APIClient
    
    /// Initialize the AssetLoader with an optional base URL
    /// - Parameter baseURL: The base URL for the API. Uses default if not provided
    public init(baseURL: String? = nil) {
        if let baseURL = baseURL {
            self.apiClient = APIClient(baseURL: baseURL)
        } else {
            self.apiClient = APIClient()
        }
    }
    
    /// Load download information for a specific download ID
    /// - Parameter downloadId: The ID of the download to fetch
    /// - Returns: DownloadResponse containing asset URLs and metadata
    /// - Throws: APIError if the request fails
    public func loadDownload(downloadId: String) async throws -> DownloadResponse {
        return try await apiClient.getDownload(downloadId: downloadId)
    }
    
    /// Convenience method to get just the asset URLs from a download
    /// - Parameter downloadId: The ID of the download to fetch
    /// - Returns: Array of asset URL strings
    /// - Throws: APIError if the request fails
    public func getAssetURLs(downloadId: String) async throws -> [String] {
        let download = try await loadDownload(downloadId: downloadId)
        return download.assets
    }
    
    /// Download asset data from a URL
    /// - Parameter urlString: The URL string of the asset to download
    /// - Returns: Data of the downloaded asset
    /// - Throws: AssetDownloadError if the download fails
    public func downloadAsset(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw AssetDownloadError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw AssetDownloadError.downloadFailed
            }
            
            return data
        } catch {
            throw AssetDownloadError.networkError(error)
        }
    }
}

/// Errors that can occur when downloading assets
public enum AssetDownloadError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid asset URL"
        case .downloadFailed:
            return "Asset download failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
