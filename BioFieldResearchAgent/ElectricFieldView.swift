//
//  ElectrincFieldView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 12.04.2025.
//

import SwiftUI

struct ElectricFieldView: View {
    @State private var voltages: [Double] = (0..<8).map { _ in Double.random(in: 0...1) }
    @State private var useGradIDW: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.8

            let sensorData = precalculateSensorData(center: center, radius: radius)
            let centerVoltage = idw(x: Double(center.x), y: Double(center.y), sensorData: sensorData, voltages: voltages)
            let circleVoltages = calculateCircleVoltages(center: center, radius: radius, sensorData: sensorData, voltages: voltages)

            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                ForEach(0..<8) { index in
                    Circle()
                        .fill(colorForVoltage(voltages[index]))
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .frame(width: 16, height: 16)
                        .position(sensorData.sensorPoints[index])
                }

                Canvas { context, size in
                    for x in 0..<Int(size.width) {
                        for y in 0..<Int(size.height) {
                            let distanceToCenter = sqrt(pow(Double(x) - center.x, 2) + pow(Double(y) - center.y, 2))
                            if distanceToCenter <= radius {
                                let voltage = calculateVoltage(x: Double(x), y: Double(y), sensorData: sensorData, voltages: voltages, centerVoltage: centerVoltage, circleVoltages: circleVoltages, center: center, radius: radius)
                                let color = colorForVoltage(voltage)
                                context.fill(Path(CGRect(x: Double(x), y: Double(y), width: 1, height: 1)), with: .color(color))
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                VStack {
                    Toggle("Use Grad-IDW", isOn: $useGradIDW)
                    Button("Regenerate") {
                        voltages = modifyVoltages(voltages: voltages)
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
            }
        }
        .padding()
    }

    struct SensorData {
        let sensorPoints: [CGPoint]
    }
    
    func modifyVoltages(voltages: [Double]) -> [Double] {
        return voltages.map { voltage in
            let change = Double.random(in: -0.1...0.1)
            let modifiedVoltage = voltage + change
            return max(0, min(1, modifiedVoltage)) // Ensure the voltage stays within 0...1
        }
    }

    func precalculateSensorData(center: CGPoint, radius: Double) -> SensorData {
        let angles = (0..<8).map { Double($0) * 2 * .pi / 8 }
        let sensorPoints = angles.map { CGPoint(x: center.x + radius * cos($0), y: center.y + radius * sin($0)) }
        return SensorData(sensorPoints: sensorPoints)
    }

    func calculateCircleVoltages(center: CGPoint, radius: Double, sensorData: SensorData, voltages: [Double]) -> [Double] {
        let resolution = 360 // Number of points on the circle
        var circleVoltages: [Double] = []

        for i in 0..<resolution {
            let angle = Double(i) * 2 * .pi / Double(resolution)
            let circleX = center.x + radius * cos(angle)
            let circleY = center.y + radius * sin(angle)
            let circleVoltage = idw(x: circleX, y: circleY, sensorData: sensorData, voltages: voltages)
            circleVoltages.append(circleVoltage)
        }
        return circleVoltages
    }

    func calculateVoltage(x: Double, y: Double, sensorData: SensorData, voltages: [Double], centerVoltage: Double, circleVoltages: [Double], center: CGPoint, radius: Double) -> Double {
        if useGradIDW {
            return gradIDW(x: x, y: y, centerVoltage: centerVoltage, circleVoltages: circleVoltages, center: center, radius: radius)
        } else {
            return idw(x: x, y: y, sensorData: sensorData, voltages: voltages)
        }
    }

    func idw(x: Double, y: Double, sensorData: SensorData, voltages: [Double], power: Double = 2) -> Double {
        var numerator: Double = 0
        var denominator: Double = 0

        for i in 0..<8 {
            let dx = x - Double(sensorData.sensorPoints[i].x)
            let dy = y - Double(sensorData.sensorPoints[i].y)
            let distanceSquared = dx * dx + dy * dy

            if distanceSquared == 0 {
                return voltages[i]
            }

            let distance = sqrt(distanceSquared)
            let weight = 1 / pow(distance, power)

            numerator += weight * voltages[i]
            denominator += weight
        }

        return denominator == 0 ? 0 : numerator / denominator
    }

    func gradIDW(x: Double, y: Double, centerVoltage: Double, circleVoltages: [Double], center: CGPoint, radius: Double) -> Double {
        let angle = atan2(y - center.y, x - center.x)
        let circleIndex = Int(round(angle / (2 * .pi) * 360))

        let positiveIndex = (circleIndex % 360 + 360) % 360

        let circleVoltage = circleVoltages[positiveIndex]

        let distanceToCenter = sqrt(pow(x - center.x, 2) + pow(y - center.y, 2))
        return centerVoltage + (circleVoltage - centerVoltage) * (distanceToCenter / radius)
    }

    func colorForVoltage(_ voltage: Double) -> Color {
        let hue = 0.66 - (0.66 * voltage)
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
}

struct ElectricFieldView_Previews: PreviewProvider {
    static var previews: some View {
        ElectricFieldView()
    }
}
