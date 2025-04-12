//
//  VoltageHeatmapView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 10.04.25.
//

import SwiftUI

struct VoltageHeatmapView: View {
    let simGridSize = 128  // smaller grid for performance
    let displayScale = 1  // upscale for visualization

    @State private var voltages = [Double](repeating: 0.0, count: 8)
    @State private var field: [[Double]] = []
    @State private var selectedMethod = "Laplace"  // ComboBox selection for method
    
    let methods = ["Laplace", "RBF"]  // Available methods in ComboBox

    var body: some View {
        VStack {
            // ComboBox (Picker) to select between Laplace and RBF
            Picker("Select Method", selection: $selectedMethod) {
                ForEach(methods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }
            .pickerStyle(SegmentedPickerStyle())  // Segmented style looks like a ComboBox
            .padding()
            
            Canvas { context, size in
                guard !field.isEmpty else { return }

                // Display the voltage grid
                for y in 0..<field.count {
                    for x in 0..<field[y].count {
                        let v = min(max(field[y][x], 0.0), 1.0) // Clamp between 0 and 1
                        let color = Color(hue: 1.0 - v, saturation: 1.0, brightness: 1.0)
                        context.fill(
                            Path(CGRect(x: CGFloat(x * displayScale),
                                         y: CGFloat(y * displayScale),
                                         width: CGFloat(displayScale),
                                         height: CGFloat(displayScale))),
                            with: .color(color)
                        )
                    }
                }
            }
            .frame(width: CGFloat(simGridSize * displayScale),
                   height: CGFloat(simGridSize * displayScale))

            Button("Randomize Voltages") {
                voltages = (0..<8).map { _ in Double.random(in: 0...1) }
                solveAsync()
            }
        }
        .onAppear {
            solveAsync()
        }
    }

    func solveAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result: [[Double]]
            if selectedMethod == "Laplace" {
                result = solveLaplace(size: simGridSize, voltages: voltages)
            } else {
                result = solveRBF(size: simGridSize, voltages: voltages)
            }
            DispatchQueue.main.async {
                self.field = result
            }
        }
    }

    func solveLaplace(size: Int, voltages: [Double]) -> [[Double]] {
        var grid = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        var mask = Array(repeating: Array(repeating: false, count: size), count: size)

        let center = size / 2
        let radius = Double(center - 1)

        // Interpolate voltages across the boundary
        for i in 0..<size {
            let angle = 2 * Double.pi * Double(i) / Double(size)
            let x = center + Int(radius * cos(angle))
            let y = center + Int(radius * sin(angle))

            let sector = Double(i) / Double(size) * 8.0
            let indexA = Int(floor(sector)) % 8
            let indexB = (indexA + 1) % 8
            let t = sector - floor(sector)
            let voltage = (1 - t) * voltages[indexA] + t * voltages[indexB]

            grid[y][x] = voltage
            mask[y][x] = true
        }

        let maxIterations = 1000
        let tolerance = 1e-4

        for _ in 0..<maxIterations {
            var maxDiff = 0.0
            var newGrid = grid

            for y in 1..<size - 1 {
                for x in 1..<size - 1 {
                    let dx = x - center
                    let dy = y - center
                    if sqrt(Double(dx*dx + dy*dy)) > radius { continue }
                    if mask[y][x] { continue }

                    let newVal = 0.25 * (grid[y+1][x] + grid[y-1][x] + grid[y][x+1] + grid[y][x-1])
                    maxDiff = max(maxDiff, abs(newVal - grid[y][x]))
                    newGrid[y][x] = newVal
                }
            }

            grid = newGrid
            if maxDiff < tolerance {
                break
            }
        }

        return grid
    }

    func solveRBF(size: Int, voltages: [Double]) -> [[Double]] {
        var grid = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        let center = size / 2
        let radius = Double(center - 1)

        struct RBFSource {
            let x: Double
            let y: Double
            let voltage: Double
        }

        let sources: [RBFSource] = (0..<8).map { i in
            let angle = 2 * Double.pi * Double(i) / 8.0
            let x = Double(center) + radius * cos(angle)
            let y = Double(center) + radius * sin(angle)
            return RBFSource(x: x, y: y, voltage: voltages[i])
        }

        //let epsilon = 0.01 // smaller epsilon for smoother effect
        let epsilon = 1.0 / (Double(size) * 4.0)

        for y in 0..<size {
            for x in 0..<size {
                let dx = x - center
                let dy = y - center
                if sqrt(Double(dx * dx + dy * dy)) > radius { continue }

                var numerator = 0.0
                var denominator = 0.0
                for source in sources {
                    let dist2 = pow(Double(x) - source.x, 2) + pow(Double(y) - source.y, 2)
                    let weight = exp(-dist2 * epsilon)
                    numerator += weight * source.voltage
                    denominator += weight
                }

                grid[y][x] = denominator > 0 ? numerator / denominator : 0.0
            }
        }

        return grid
    }
}



struct VoltageHeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        VoltageHeatmapView()
    }
}
