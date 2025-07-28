//
//  MetaInteractiveView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 12.07.2025.
//
import SwiftUI
import MetalKit

final class MetalInteractiveView: MTKView {
    weak var renderer: MetalRenderer?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        let trackingArea = NSTrackingArea(rect: self.bounds,
                                          options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect, .enabledDuringMouseDrag],
                                          owner: self,
                                          userInfo: nil)
        self.addTrackingArea(trackingArea)
        self.window?.acceptsMouseMovedEvents = true
    }

    // Track mouse state
    override func mouseDown(with event: NSEvent) {
        renderer?.isMousePressed = true
        updateMousePosition(event)
    }

    override func mouseUp(with event: NSEvent) {
        renderer?.isMousePressed = false
        updateMousePosition(event)
    }

    override func mouseMoved(with event: NSEvent) {
        updateMousePosition(event)
    }

    override func mouseDragged(with event: NSEvent) {
        updateMousePosition(event)
    }

    private func updateMousePosition(_ event: NSEvent) {
        let pointInView = convert(event.locationInWindow, from: nil)

        // Conver point to pixels: Multiply by screen scale (e.g. 2.0 on Retina)
        let scale = window?.backingScaleFactor ?? 1.0
        let pixelPoint = CGPoint(x: pointInView.x * scale, y: pointInView.y * scale)

        renderer?.mousePosition = SIMD2<Float>(Float(pixelPoint.x), Float(pixelPoint.y))
    }
}
