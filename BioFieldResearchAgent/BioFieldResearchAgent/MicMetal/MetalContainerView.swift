//
//  MicMetalContainerView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import SwiftUI
import MetalKit

#if os(macOS)

public typealias NativeView = NSView
public typealias NativeApplication = NSApplication
public typealias ViewRepresentable = NSViewRepresentable
public typealias ViewControllerRepresentable = NSViewControllerRepresentable

#elseif os(iOS)

public typealias NativeView = UIView
public typealias NativeApplication = UIApplication
public typealias ViewRepresentable = UIViewRepresentable
public typealias ViewControllerRepresentable = UIViewControllerRepresentable

#endif

struct MetalContainerView: ViewRepresentable {
    @Binding var amplitude: Float
    @Binding var shaderType: ShaderType
    
    func makeCoordinator() -> MetalRenderer {
        return MetalRenderer(metalView: view)
    }
#if os(macOS)
    func makeNSView(context: Context) -> MTKView {
        view.device = MTLCreateSystemDefaultDevice()
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = false
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.amplitude = amplitude
        context.coordinator.updateShader(to: shaderType)
    }

    private let view = MTKView()
#elseif os(iOS)
    func makeUIView(context: Context) -> MTKView {
        view.device = MTLCreateSystemDefaultDevice()
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = false
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.amplitude = amplitude
        context.coordinator.updateShader(to: shaderType)
    }

    private let view = MTKView()
#endif
}
