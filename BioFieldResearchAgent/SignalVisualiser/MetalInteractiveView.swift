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

    private var smoothMousePosition: SIMD2<Float> = .zero
    private var animationTimer: Timer?
    private var animationStartTime: Date?
    private let animationDuration: TimeInterval = 1.0

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            smoothMousePosition = centerInPixels()
            renderer?.smoothMousePosition = smoothMousePosition
        }
    }

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
        startAnimation()
    }

    override func mouseUp(with event: NSEvent) {
        renderer?.isMousePressed = false
        startAnimation()
    }

    override func mouseMoved(with event: NSEvent) {
        updateMousePosition(event)
    }

    override func mouseDragged(with event: NSEvent) {
        updateMousePosition(event)
    }

    private func pointInPixels(from point: NSPoint) -> SIMD2<Float> {
        let scale = window?.backingScaleFactor ?? 1.0
        let pixelPoint = CGPoint(x: point.x * scale, y: point.y * scale)
        return SIMD2<Float>(Float(pixelPoint.x), Float(pixelPoint.y))
    }

    private func centerInPixels() -> SIMD2<Float> {
        let centerPoint = NSPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        return pointInPixels(from: centerPoint)
    }

    private func updateMousePosition(_ event: NSEvent) {
        let pointInView = convert(event.locationInWindow, from: nil)
        renderer?.mousePosition = pointInPixels(from: pointInView)
    }

    private func startAnimation() {
        animationStartTime = Date()
        if animationTimer == nil {
            animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { [weak self] _ in
                self?.updateSmoothPosition()
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func updateSmoothPosition() {
        guard let renderer = renderer else { return }

        let targetPosition: SIMD2<Float>
        if renderer.isMousePressed {
            targetPosition = renderer.mousePosition
        } else {
            targetPosition = centerInPixels()
        }

        let elapsedTime = Date().timeIntervalSince(animationStartTime ?? Date())
        let t = min(elapsedTime / animationDuration, 1.0)
        let easedT = easeOut(t)

        smoothMousePosition = mix(smoothMousePosition, targetPosition, t: Float(easedT))
        renderer.smoothMousePosition = smoothMousePosition

        if t >= 1.0 {
            stopAnimation()
        }
    }

    private func easeOut(_ t: TimeInterval) -> TimeInterval {
        return 1 - pow(1 - t, 3)
    }
}

func mix(_ a: SIMD2<Float>, _ b: SIMD2<Float>, t: Float) -> SIMD2<Float> {
    return a * (1 - t) + b * t
}
