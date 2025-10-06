//
//  SplashScreenAppixView.swift
//  AssetLoader
//
//  Created by Ivan Trotter on 8/16/25.
//

import SwiftUI

public struct SplashScreenAppixView: View {
    /// Optional progress current value to render a progress bar.
    private let progressCurrent: Int?
    /// Optional total value for the progress bar.
    private let progressTotal: Int?
    
    public init(progressCurrent: Int? = nil, progressTotal: Int? = nil) {
        self.progressCurrent = progressCurrent
        self.progressTotal = progressTotal
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Image("splash1242x2208", bundle: .module)
                .resizable()
                .scaledToFit()
            
            if let current = progressCurrent, let total = progressTotal, total > 0 {
                VStack {
                    ProgressView(value: Double(current), total: Double(total))
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
    }
}
