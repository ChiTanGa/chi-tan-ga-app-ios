//
//  MetalContentView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import SwiftUI

struct MetalContentView: View {
    @State private var amplitude: Float = 0.0
    private let audioManager = AudioInputManager()

    var body: some View {
        MetalContainerView(amplitude: $amplitude)
            .ignoresSafeArea()
            .onAppear {
                audioManager.onAmplitudeUpdate = { level in
                    amplitude = level
                }
            }
    }
}
