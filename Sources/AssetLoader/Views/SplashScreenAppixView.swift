//
//  SplashScreenAppixView.swift
//  AssetLoader
//
//  Created by Ivan Trotter on 8/16/25.
//

import SwiftUI

public struct SplashScreenAppixView: View {
    
    public init() {}
    
    public var body: some View {
        Image("splash1242x2208", bundle: .module)
            .resizable()
            .scaledToFit()
    }
}
