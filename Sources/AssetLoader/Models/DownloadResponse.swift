import Foundation

/// Model representing the response from the downloads API endpoint
public struct DownloadResponse: Codable, Sendable {
    /// Unique identifier for the download
    public let id: String
    
    /// Type of the download (e.g., "appix")
    public let type: String
    
    /// Version number of the download
    public let version: Int
    
    /// Array of asset URLs
    public let assets: [String]
    
    /// Initializer for creating a DownloadResponse instance
    public init(id: String, type: String, version: Int, assets: [String]) {
        self.id = id
        self.type = type
        self.version = version
        self.assets = assets
    }
} 