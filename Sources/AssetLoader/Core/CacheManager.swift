import Foundation

class CacheManager {
//    static let shared = CacheManager()

    
    private let documentsPath: URL
    private let session = URLSession.shared
    
    public init() {
        // Get the Documents directory
        documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Converts a full URL to a local file path
    /// Example: "https://speedzlestorage.blob.core.windows.net/projects/speedzle/worldMonuments/worldMonuments.png"
    /// becomes: "[Documents]/projects/speedzle/worldMonuments/worldMonuments.png"
    public func localPath(for url: String) -> URL? {
        guard let fullURL = URL(string: url) else { return nil }
        
        // Remove the scheme and host to get the path
        let pathComponents = fullURL.pathComponents
        
        // Skip the first component which is "/"
        let relevantComponents = Array(pathComponents.dropFirst())
        
        // Build the local path
        var localURL = documentsPath
        for component in relevantComponents {
            localURL.appendPathComponent(component)
        }
        
        return localURL
    }
    
    /// Checks if the asset exists locally
    public func assetExists(for url: String) -> Bool {
        guard let localPath = localPath(for: url) else { return false }
        return FileManager.default.fileExists(atPath: localPath.path)
    }
    
    /// Gets the local URL for an asset (if it exists)
    public func localURL(for url: String) -> URL? {
        guard let localPath = localPath(for: url),
              FileManager.default.fileExists(atPath: localPath.path) else {
            return nil
        }
        return localPath
    }
    
    /// Downloads and caches an asset
    public func downloadAndCache(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString),
              let localPath = localPath(for: urlString) else {
            throw CacheError.invalidURL
        }
        
        // Create directory structure if it doesn't exist
        let directoryURL = localPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        // Download the file
        let (data, response) = try await session.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CacheError.downloadFailed
        }
        
        // Save to local path
        try data.write(to: localPath)
        
        return localPath
    }
    
    /// Gets the asset URL, downloading if necessary
    public func getAsset(from urlString: String) async throws -> URL {
        // Check if asset exists locally
        if let localURL = localURL(for: urlString) {
            print("ITR..File exists locally: \(localURL)")
            return localURL
        }
        
        // Download and cache the asset
        return try await downloadAndCache(from: urlString)
    }
    
    /// Clears all cached assets
    public func clearCache() throws {
        let cacheContents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
        
        for item in cacheContents {
            try FileManager.default.removeItem(at: item)
        }
    }
    
    /// Gets the total size of cached assets
    public func getCacheSize() throws -> Int64 {
        let cacheContents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        for item in cacheContents {
            let resourceValues = try item.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(resourceValues.fileSize ?? 0)
        }
        
        return totalSize
    }
}

enum CacheError: Error {
    case invalidURL
    case downloadFailed
    case fileWriteFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .downloadFailed:
            return "Failed to download asset"
        case .fileWriteFailed:
            return "Failed to write file to cache"
        }
    }
}
