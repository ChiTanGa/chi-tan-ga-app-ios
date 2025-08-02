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
    @Binding var signalGain: Float
    @Binding var shaderType: ShaderType
    @Binding var signalDownsampleProcessor: SignalDownsampleProcessor
    @Binding var frequencySpectrumProcessor: FrequencySpectrumProcessor
    
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
        view.renderer = context.coordinator
        return view
    }

    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.amplitude = amplitude
        context.coordinator.signalGain = signalGain
        context.coordinator.signalDownsampleProcessor = signalDownsampleProcessor
        context.coordinator.freqAnalyserProcessor = frequencySpectrumProcessor
        context.coordinator.updateShader(to: shaderType)
        
        
    }
#elseif os(iOS)
    func makeUIView(context: Context) -> MTKView {
        view.device = MTLCreateSystemDefaultDevice()
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = false
        view.delegate = context.coordinator
        view.renderer = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.amplitude = amplitude
        context.coordinator.signalGain = signalGain
        context.coordinator.signalDownsampleProcessor = signalDownsampleProcessor
        context.coordinator.freqAnalyserProcessor = frequencySpectrumProcessor
        context.coordinator.updateShader(to: shaderType)
    }
#endif
    private let view = MetalInteractiveView()
}
