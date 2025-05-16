//
//  SignalCircularBuffer.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 06.05.2025.
//

import AVFoundation

class SignalCircularBufferProcessor : ObservableObject, SignalProcessor {
    private let circularBufferSize: Int
    
    private var circularBuffer: [Float]
    private var circularIndex: Int = 0
    private let bufferQueue = DispatchQueue(label: "circular.buffer.queue")
    
    init(circularBufferSize: Int) {
        self.circularBufferSize = circularBufferSize
        self.circularBuffer = [Float](repeating: 0.0, count: circularBufferSize)
    }
    
    func processIncomingAudioBuffer(_ signalDataBuffer: UnsafeBufferPointer<Float>) {
        bufferQueue.sync {
            for value in signalDataBuffer {
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
