//
//  MetalRenderer.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import MetalKit
import simd
import SwiftUICore

struct EmotionAnchor {
    var angle: Float       // 0 ... 360
    var color: SIMD3<Float>  // RGB, each 0.0 ... 1.0
}

class MetalRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var time: Float = 0
    var amplitude: Float = 0
    var mousePosition: SIMD2<Float> = SIMD2<Float>(0, 0)
    var currentShaderType: ShaderType = .dream
    var signalDownsampleProcessor: SignalDownsampleProcessor = SignalDownsampleProcessor(circularBufferSize: 1024, downsamplingRate: 1, downsamplingMode: DownsamplingMode.average)
    var freqAnalyserProcessor: FrequencySpectrumProcessor = FrequencySpectrumProcessor(bufferSize: 2048)
    private var library: MTLLibrary!
    let pipelineDesc = MTLRenderPipelineDescriptor()

    init(metalView: MTKView) {
        super.init()
        self.device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = self

        commandQueue = device.makeCommandQueue()

        library = device.makeDefaultLibrary()
        let vertex = library?.makeFunction(name: currentShaderType.vertexFunctionName)
        let fragment = library?.makeFunction(name: currentShaderType.fragmentFunctionName) 
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertex
        pipelineDesc.fragmentFunction = fragment
        pipelineDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    }
    
    func updateShader(to newShaderType: ShaderType) {
        guard let library = library else {
            print("❌ Shader library is not available, shader cant be updated")
            return
        }
        
        guard currentShaderType != newShaderType else { return }
        
        guard let vertex = library.makeFunction(name: newShaderType.vertexFunctionName),
              let fragment = library.makeFunction(name: newShaderType.fragmentFunctionName) else {
            print("❌ Failed to load shader functions")
            return
        }

        let newPipelineDesc = MTLRenderPipelineDescriptor()
        newPipelineDesc.vertexFunction = vertex
        newPipelineDesc.fragmentFunction = fragment
        newPipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: newPipelineDesc)
            print("✅ Shader updated to \(newShaderType)")
            currentShaderType = newShaderType
        } catch {
            print("❌ Error updating shader type: \(error)")
        }
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let desc = view.currentRenderPassDescriptor,
              let cmdBuffer = commandQueue.makeCommandBuffer(),
              let encoder = cmdBuffer.makeRenderCommandEncoder(descriptor: desc) else { return }

        time += 1 / Float(view.preferredFramesPerSecond)

        encoder.setRenderPipelineState(pipelineState)

        let vertices: [simd_float2] = [
            [-1, -1], [1, -1], [-1, 1],
            [1, -1], [1, 1], [-1, 1]
        ]
        var resolution = simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        
        encoder.setVertexBuffer(device.makeBuffer(bytes: vertices, length: MemoryLayout<simd_float2>.stride * vertices.count), offset: 0, index: 0)
        encoder.setVertexBuffer(device.makeBuffer(bytes: &time, length: MemoryLayout<Float>.size), offset: 0, index: 2)
        encoder.setVertexBuffer(device.makeBuffer(bytes: &amplitude, length: MemoryLayout<Float>.size), offset: 0, index: 3)
        encoder.setVertexBuffer(device.makeBuffer(bytes: &resolution, length: MemoryLayout<simd_float2>.size), offset: 0, index: 4)
        
        
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<simd_float2>.stride, index: 0)
        encoder.setFragmentBytes(&mousePosition, length: MemoryLayout<simd_float2>.stride, index: 1)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.stride, index: 2) // index 2 for time
        encoder.setFragmentBytes(&amplitude, length: MemoryLayout<Float>.stride, index: 3) // index 3 for amplitude

        let currentBufferData = signalDownsampleProcessor.getCurrentBuffer()
        var bufferLength = currentBufferData.count;

        currentBufferData.withUnsafeBytes { (ptr) in
            encoder.setFragmentBytes(ptr.baseAddress!, length: bufferLength * MemoryLayout<Float>.size, index: 5) // Use the appropriate index in your shader
        }
        encoder.setFragmentBytes(&bufferLength, length: MemoryLayout<Int>.size, index: 6)
        var signalGain = 1.0
        encoder.setFragmentBytes(&signalGain, length: MemoryLayout<Float>.size, index: 7)
        
        let frequencySpectrumBufferRawPointer = freqAnalyserProcessor.outputFrequencyBinBuffer.baseAddress!
        var frequencySpectrumBufferLenght = freqAnalyserProcessor.outputFrequencyBinBuffer.count
        encoder.setFragmentBytes(frequencySpectrumBufferRawPointer,
                                       length: MemoryLayout<Float>.stride * frequencySpectrumBufferLenght,
                                       index: 10)
        encoder.setFragmentBytes(&frequencySpectrumBufferLenght, length: MemoryLayout<Int>.size, index: 11)
        
        let anchors: [EmotionAnchor] = [
            EmotionAnchor(angle:   0, color: SIMD3(1, 1, 0)),   // Yellow
            EmotionAnchor(angle: 120, color: SIMD3(1, 0, 0)),   // Red
            EmotionAnchor(angle: 240, color: SIMD3(0, 0.5, 1)), // Blue
        ]

        let anchorBuffer = device.makeBuffer(bytes: anchors, length: anchors.count * MemoryLayout<EmotionAnchor>.stride, options: [])
        var anchorCount: UInt32 = UInt32(anchors.count)
        
        encoder.setFragmentBuffer(anchorBuffer, offset: 0, index: 12)
        encoder.setFragmentBytes(&anchorCount, length: MemoryLayout<UInt32>.stride, index: 13)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
