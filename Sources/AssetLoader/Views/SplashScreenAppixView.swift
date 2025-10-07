//
//  SplashScreenAppixView.swift
//  AssetLoader
//
//  Created by Ivan Trotter on 8/16/25.
//

import SwiftUI

public struct SplashScreenAppixView: View {
    // MARK: - Internal ViewModel
    @MainActor
    final class ViewModel: ObservableObject {
        struct Config {
            let downloadId: String
            let baseURL: String?
            let minimumDisplaySeconds: Double
            let debug: Bool
        }
        
        @Published var progressCurrent: Int = 0
        @Published var progressTotal: Int = 0
        @Published var isLoading: Bool = true
        @Published var loadError: String? = nil
        
        private let config: Config
        
        init(config: Config) {
            self.config = config
        }
        
        @MainActor
        func start(onFinished: @escaping () -> Void, onError: ((String) -> Void)?) {
            let cfg = self.config
            let isInfoEnabled = cfg.debug
            
            Task { [weak self] in
                let startTime = Date()
                let assetLoader = AssetLoader(baseURL: cfg.baseURL, debug: cfg.debug)
                
                await assetLoader.downloadWithProgress(
                    downloadId: cfg.downloadId,
                    onDownloadLoaded: { response in
                        Task { @MainActor in
                            self?.progressTotal = response.assets.count
                            self?.progressCurrent = 0
                        }
                    },
                    onProgress: { total, cached, assetName in
                        if isInfoEnabled {
                            print("ITR..Cached asset: \(assetName) (\(cached)/\(total))")
                        }
                        Task { @MainActor in
                            self?.progressTotal = total
                            self?.progressCurrent = cached
                        }
                    },
                    onComplete: { attempted, cached, failed in
                        if isInfoEnabled {
                            print("ITR..Completed caching. attempted=\(attempted) cached=\(cached) failed=\(failed)")
                        }
                    },
                    onAssetNotFound: { assetURL in
                        print("ITR..Asset not found: \(assetURL)")
                    },
                    onError: { error in
                        Task { @MainActor in
                            self?.loadError = error.localizedDescription
                            self?.isLoading = false
                            onError?(error.localizedDescription)
                        }
                    }
                )
                
                // Enforce minimum display time
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, cfg.minimumDisplaySeconds - elapsed)
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }
                
                await MainActor.run {
                    self?.isLoading = false
                    onFinished()
                }
            }
        }
    }
    
    // MARK: - Public API
    private let downloadId: String
    private let baseURL: String?
    private let minimumDisplaySeconds: Double
    private let debug: Bool
    private let onFinished: () -> Void
    private let onError: ((String) -> Void)?
    
    @StateObject private var viewModel: ViewModel
    
    public init(
        downloadId: String,
        baseURL: String? = nil,
        minimumDisplaySeconds: Double = 2,
        debug: Bool = false,
        onFinished: @escaping () -> Void,
        onError: ((String) -> Void)? = nil
    ) {
        self.downloadId = downloadId
        self.baseURL = baseURL
        self.minimumDisplaySeconds = minimumDisplaySeconds
        self.debug = debug
        self.onFinished = onFinished
        self.onError = onError
        _viewModel = StateObject(wrappedValue: ViewModel(config: .init(downloadId: downloadId, baseURL: baseURL, minimumDisplaySeconds: minimumDisplaySeconds, debug: debug)))
    }
    
    public var body: some View {
        ZStack {
            // Background color
            Rectangle()
                .fill(Color(red: 254/255, green: 135/255, blue: 0/255))
                .ignoresSafeArea()
            
            Image("logo1536x1536", bundle: .module)
                .resizable()
                .scaledToFit()

            VStack {
                Spacer()
                
                // Progress view at bottom
                if viewModel.progressTotal > 0 && viewModel.progressCurrent != viewModel.progressTotal {
                    ProgressView(value: Double(viewModel.progressCurrent), total: Double(viewModel.progressTotal))
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            viewModel.start(onFinished: onFinished, onError: onError)
        }
    }
}
