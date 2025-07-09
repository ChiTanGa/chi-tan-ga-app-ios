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
            
            ZStack {
                // Background gradient ring
                Circle()
                    .strokeBorder(
                        AngularGradient(gradient: Gradient(colors: emotions.map { $0.color }),
                                        center: .center),
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
                    let colorAtAngle = colorForTouch(location: location, center: center)
                    
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: location)
                    }
                    .stroke(LinearGradient(
                        gradient: Gradient(colors: [.white, colorAtAngle]),
                        startPoint: UnitPoint(x: center.x / geo.size.width,
                                              y: center.y / geo.size.height),
                        endPoint: UnitPoint(x: location.x / geo.size.width,
                                            y: location.y / geo.size.height)),
                            lineWidth: 4)
                    
                    // Small circle at touch location
                    Circle()
                        .fill(colorAtAngle)
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
    
    func colorForTouch(location: CGPoint, center: CGPoint) -> Color {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let angle = atan2(dy, dx)
        let degrees = (angle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        
        // Interpolate between emotions by angle
        let emotionAngles = emotions.map { $0.angle.degrees }
        let emotionColors = emotions.map { $0.color }

        for i in 0..<emotions.count {
            let a0 = emotionAngles[i]
            let a1 = emotionAngles[(i + 1) % emotions.count]
            let c0 = emotionColors[i]
            let c1 = emotionColors[(i + 1) % emotions.count]

            if angleBetween(degrees, from: a0, to: a1) {
                let t = normalizedAngle(degrees, from: a0, to: a1)
                return blendColors(c0, c1, t: t)
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
        guard let cg0 = c0.cgColor,
              let cg1 = c1.cgColor,
              let comps0 = cg0.components,
              let comps1 = cg1.components else {
            return c0
        }

        // Some CGColors have 2 components (grayscale), others 4 (RGBA)
        let r0 = comps0.count >= 3 ? comps0[0] : comps0[0]
        let g0 = comps0.count >= 3 ? comps0[1] : comps0[0]
        let b0 = comps0.count >= 3 ? comps0[2] : comps0[0]
        let a0 = comps0.count == 4 ? comps0[3] : 1.0

        let r1 = comps1.count >= 3 ? comps1[0] : comps1[0]
        let g1 = comps1.count >= 3 ? comps1[1] : comps1[0]
        let b1 = comps1.count >= 3 ? comps1[2] : comps1[0]
        let a1 = comps1.count == 4 ? comps1[3] : 1.0

        return Color(red: Double(r0 + (r1 - r0) * CGFloat(t)),
                     green: Double(g0 + (g1 - g0) * CGFloat(t)),
                     blue: Double(b0 + (b1 - b0) * CGFloat(t)),
                     opacity: Double(a0 + (a1 - a0) * CGFloat(t)))
    }

}

#Preview {
    EmotionPickerView()
}
