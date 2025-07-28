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
                                          options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                                          owner: self,
                                          userInfo: nil)
        self.addTrackingArea(trackingArea)
        self.window?.acceptsMouseMovedEvents = true
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let flippedY = bounds.height - point.y // Convert to Metal coordinate space
        renderer?.mousePosition = SIMD2<Float>(Float(point.x), Float(point.y))
    }
}
