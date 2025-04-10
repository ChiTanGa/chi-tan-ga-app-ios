//
//  VoltageHeatmapView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 10.04.25.
//

import SwiftUI

struct VoltageHeatmapView: View {
    let simGridSize = 32  // smaller grid for performance
    let displayScale = 8  // upscale for visualization

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
                        let v = field[y][x]
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

        // Define RBF kernel function (Gaussian)
        func rbf(x: Double, y: Double, cx: Double, cy: Double, epsilon: Double = 1.0) -> Double {
            let distance = (x - cx) * (x - cx) + (y - cy) * (y - cy)
            return exp(-epsilon * distance)
        }

        // Define interpolation for RBF
        func interpolate(x: Int, y: Int) -> Double {
            var value = 0.0
            let epsilon: Double = 1.0  // Adjust for sensitivity of interpolation

            // Calculate weighted sum of boundary voltages using RBF
            for i in 0..<8 {
                let angle = 2 * Double.pi * Double(i) / 8.0
                let vx = center + Int(radius * cos(angle))
                let vy = center + Int(radius * sin(angle))

                // Apply RBF kernel (distance between grid point and boundary points)
                let r = rbf(x:Double(x), y: Double(y), cx: Double(vx), cy: Double(vy), epsilon: epsilon)
                value += voltages[i] * r
            }
            return value
        }

        // Apply interpolation across the grid (whole grid, not just boundary points)
        for y in 0..<size {
            for x in 0..<size {
                let dx = x - center
                let dy = y - center
                if sqrt(Double(dx * dx + dy * dy)) <= radius {  // Only interpolate inside the circle
                    grid[y][x] = interpolate(x: x, y: y)
                }
            }
        }

        // Normalize values to keep them within 0..1 range
        let minVal = grid.flatMap { $0 }.min() ?? 0
        let maxVal = grid.flatMap { $0 }.max() ?? 1
        let range = maxVal - minVal

        for y in 0..<size {
            for x in 0..<size {
                if range > 0 {
                    grid[y][x] = (grid[y][x] - minVal) / range  // Normalize to [0, 1]
                } else {
                    grid[y][x] = 0.0
                }
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
