//
//  AudioCircularBuffer.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 04.05.2025.
//

import AVFoundation

enum DownsamplingMode : String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case peak
    case average
    case first
}

class SignalDownsampleProcessor : ObservableObject, SignalProcessor {
    private let circularBufferSize: Int
    private let downsamplingRate: Int
    private let downsamplingMode: DownsamplingMode
    
    private var circularBuffer: [Float]
    private var circularIndex: Int = 0
    private let bufferQueue = DispatchQueue(label: "circular.buffer.queue")
    
    init(circularBufferSize: Int, downsamplingRate: Int = 1, downsamplingMode: DownsamplingMode = .peak) {
        self.circularBufferSize = circularBufferSize
        self.downsamplingRate = downsamplingRate
        self.downsamplingMode = downsamplingMode
        self.circularBuffer = [Float](repeating: 0.0, count: circularBufferSize)
    }
    
    func processIncomingAudioBuffer(_ signalDataBuffer: UnsafeBufferPointer<Float>) {
        let batchCount = signalDataBuffer.count / downsamplingRate
        guard batchCount > 0 else { return }
        guard let signalDataPointer = signalDataBuffer.baseAddress else { return }

        var downsampledValues = [Float](repeating: 0.0, count: batchCount)

        DispatchQueue.concurrentPerform(iterations: batchCount) { batchIndex in
            let framePosition = batchIndex * downsamplingRate
            let sliceLength = min(downsamplingRate, signalDataBuffer.count - framePosition)
            let slice = UnsafeBufferPointer(start: signalDataPointer + framePosition, count: sliceLength)
            
            switch downsamplingMode {
            case .first:
                downsampledValues[batchIndex] = slice[0]
            case .average:
                downsampledValues[batchIndex] = slice.reduce(0, +) / Float(slice.count)
            case .peak:
                let maxVal = slice.max() ?? 0
                let minVal = slice.min() ?? 0
                downsampledValues[batchIndex] = abs(maxVal) > abs(minVal) ? maxVal : minVal
            }
        }

        bufferQueue.sync {
            for value in downsampledValues {
                circularBuffer[circularIndex] = value
                circularIndex = (circularIndex + 1) % circularBufferSize
            }
        }
    }

    func getCurrentBuffer() -> [Float] {
        return bufferQueue.sync {
            if circularIndex == 0 {
                return circularBuffer
            } else {
                return Array(circularBuffer[circularIndex..<circularBufferSize] + circularBuffer[0..<circularIndex])
            }
        }
    }
}
