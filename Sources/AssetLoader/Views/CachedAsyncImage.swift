import SwiftUI

public struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: Image?
    @State private var isLoading = false
    @State private var error: Error?
    
    public init(
        url urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        Group {
            if let image = image {
                content(image)
            } else if isLoading {
                placeholder()
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            } else if error != nil {
                placeholder()
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    )
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard image == nil && !isLoading else { return }
        
        let cacheManager = CacheManager(debug: false)
        isLoading = true
        error = nil
        
        Task {
            do {
                let localURL = try await cacheManager.getAsset(from: urlString)
                
                await MainActor.run {
                    if let data = try? Data(contentsOf: localURL),
                       let uiImage = UIImage(data: data) {
                        self.image = Image(uiImage: uiImage)
                    } else {
                        self.error = CacheError.fileWriteFailed
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

// Convenience initializer for simple cases
public extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
    init(url urlString: String) {
        self.init(url: urlString) { image in
            image
        } placeholder: {
            AnyView(
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            )
        }
    }
}
