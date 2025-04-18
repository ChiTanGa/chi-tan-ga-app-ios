//
//  MetalRenderer3.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import MetalKit
import simd

class MetalRenderer3: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var time: Float = 0
    var amplitude: Float = 0

    init(metalView: MTKView) {
        super.init()
        self.device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = self

        commandQueue = device.makeCommandQueue()

        let lib = device.makeDefaultLibrary()
        let vertex = lib?.makeFunction(name: "basic_vertex") // Assuming you'll keep this name
        let fragment = lib?.makeFunction(name: "basic_fragment") // Assuming you'll keep this name
        //let vertex = lib?.makeFunction(name: "vertex_cloud")
        //let fragment = lib?.makeFunction(name: "fragment_cloud")
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertex
        pipelineDesc.fragmentFunction = fragment
        pipelineDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
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
        encoder.setVertexBuffer(device.makeBuffer(bytes: vertices, length: MemoryLayout<simd_float2>.stride * vertices.count), offset: 0, index: 0)

        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.stride, index: 2) // index 2 for time
        encoder.setFragmentBytes(&amplitude, length: MemoryLayout<Float>.stride, index: 3) // index 3 for amplitude

        // Assuming u_resolution is at index 0 and u_mouse at index 1 in the shader
        var resolution = simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<simd_float2>.stride, index: 0)
        var mousePosition = simd_float2(0, 0) // You might want to update this based on user interaction
        encoder.setFragmentBytes(&mousePosition, length: MemoryLayout<simd_float2>.stride, index: 1)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
