//
//  EmotionLabelingView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 09.07.2025.
//

import SwiftUI

struct Emotion {
    let name: String
    let color: Color
    let icon: String
    let angle: Angle
}

struct EmotionPickerView: View {
    let emotions: [Emotion] = [
        Emotion(name: "Happy",   color: .yellow, icon: "sun.max.fill",   angle: .degrees(0)),
        Emotion(name: "Angry",   color: .red,    icon: "flame.fill",     angle: .degrees(120)),
        Emotion(name: "Relaxed", color: .blue,   icon: "leaf.fill",      angle: .degrees(240))
    ]
    
    @State private var touchLocation: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.4
            // Create gradient stops at 0°, 120°, 240°, and wrap back to 360° = 0°
            let angularStops: [Gradient.Stop] = [
                .init(color: .yellow, location: 0.0),
                .init(color: .red,    location: 1/3),
                .init(color: .blue,   location: 2/3),
                .init(color: .yellow, location: 1.0) // same as start
            ]
            
            ZStack {
                // Background gradient ring
                Circle()
                    .strokeBorder(
                        AngularGradient(gradient: Gradient(stops: angularStops), center: .center),
                        lineWidth: 20
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                
                // Emotion icons around the circle
                ForEach(emotions, id: \.name) { emotion in
                    let angleRad = CGFloat(emotion.angle.radians)
                    let x = center.x + cos(angleRad) * radius
                    let y = center.y + sin(angleRad) * radius
                    
                    VStack {
                        Image(systemName: emotion.icon)
                            .foregroundColor(emotion.color)
                            .font(.title)
                        Text(emotion.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .position(x: x, y: y)
                }
                
                // Line from center to touch
                if let location = touchLocation {
                    let colorAtTouch = colorForTouch(location: location, center: center, radius: radius)

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: location)
                    }
                    .stroke(LinearGradient(
                        gradient: Gradient(colors: [.white, colorAtTouch]),
                        startPoint: UnitPoint(x: center.x / geo.size.width,
                                              y: center.y / geo.size.height),
                        endPoint: UnitPoint(x: location.x / geo.size.width,
                                            y: location.y / geo.size.height)),
                        lineWidth: 4
                    )

                    Circle()
                        .fill(colorAtTouch)
                        .frame(width: 16, height: 16)
                        .position(location)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        self.touchLocation = value.location
                    }
                    .onEnded { _ in
                        // keep the last touch, or reset: self.touchLocation = nil
                    }
            )
        }
    }
    
    func colorForTouch(location: CGPoint, center: CGPoint, radius: CGFloat) -> Color {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        let clampedDistance = min(distance / radius, 1.0)
        
        let angle = atan2(dy, dx)
        let degrees = (angle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        
        // Interpolate between anchor colors based on angle
        let emotionAngles = emotions.map { $0.angle.degrees }
        let emotionColors = emotions.map { $0.color }

        for i in 0..<emotions.count {
            let a0 = emotionAngles[i]
            let a1 = emotionAngles[(i + 1) % emotions.count]
            let c0 = emotionColors[i]
            let c1 = emotionColors[(i + 1) % emotions.count]

            if angleBetween(degrees, from: a0, to: a1) {
                let t = normalizedAngle(degrees, from: a0, to: a1)
                let baseColor = blendColors(c0, c1, t: t)
                return blendColors(.white, baseColor, t: clampedDistance)
            }
        }
        return .white
    }
    
    func angleBetween(_ angle: Double, from: Double, to: Double) -> Bool {
        let a = (angle - from + 360).truncatingRemainder(dividingBy: 360)
        let b = (to - from + 360).truncatingRemainder(dividingBy: 360)
        return a <= b
    }
    
    func normalizedAngle(_ angle: Double, from: Double, to: Double) -> Double {
        let a = (angle - from + 360).truncatingRemainder(dividingBy: 360)
        let b = (to - from + 360).truncatingRemainder(dividingBy: 360)
        return b == 0 ? 0 : a / b
    }
    
    func blendColors(_ c0: Color, _ c1: Color, t: Double) -> Color {
        let (r0, g0, b0, a0) = rgbaComponents(of: c0)
        let (r1, g1, b1, a1) = rgbaComponents(of: c1)

        return Color(
            red: r0 + (r1 - r0) * t,
            green: g0 + (g1 - g0) * t,
            blue: b0 + (b1 - b0) * t,
            opacity: a0 + (a1 - a0) * t
        )
    }

    
    func rgbaComponents(of color: Color) -> (r: Double, g: Double, b: Double, a: Double) {
        #if os(macOS)
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return (1, 1, 1, 1) // fallback white
        }
        return (Double(rgbColor.redComponent),
                Double(rgbColor.greenComponent),
                Double(rgbColor.blueComponent),
                Double(rgbColor.alphaComponent))
        #else
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #endif
    }


}

#Preview {
    EmotionPickerView()
}
