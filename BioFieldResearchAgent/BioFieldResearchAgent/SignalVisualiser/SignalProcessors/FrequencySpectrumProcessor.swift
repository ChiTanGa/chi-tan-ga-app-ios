//
//  PerformFFT.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 06.05.2025.
//

import Accelerate

class FrequencySpectrumProcessor: ObservableObject, SignalProcessor {
    private let inputSignalBufferSize: Int
    private let outputFrequencyBinBufferSize: Int
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    private let window: [Float]
    
    private let windowedInput: UnsafeMutableBufferPointer<Float>
    private let real: UnsafeMutableBufferPointer<Float>
    private let imag: UnsafeMutableBufferPointer<Float>
    
    var outputFrequencyBinBuffer: UnsafeMutableBufferPointer<Float>

    init(bufferSize: Int) {
        precondition(bufferSize > 0 && bufferSize.isPowerOfTwo)

        self.inputSignalBufferSize = bufferSize
        self.outputFrequencyBinBufferSize = bufferSize / 2
        self.log2n = vDSP_Length(log2(Float(bufferSize)))
        
        // FFT setup
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            fatalError("Failed to create FFT setup")
        }
        self.fftSetup = setup

        // Hann window
        var windowTemp = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&windowTemp, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        self.window = windowTemp

        // Allocate working buffers
        self.windowedInput = UnsafeMutableBufferPointer<Float>.allocate(capacity: bufferSize)
        self.real = UnsafeMutableBufferPointer<Float>.allocate(capacity: bufferSize / 2)
        self.imag = UnsafeMutableBufferPointer<Float>.allocate(capacity: bufferSize / 2)
        self.outputFrequencyBinBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: outputFrequencyBinBufferSize)
    }

    deinit {
        windowedInput.deallocate()
        real.deallocate()
        imag.deallocate()
        outputFrequencyBinBuffer.deallocate()
        vDSP_destroy_fftsetup(fftSetup)
    }

    func processIncomingAudioBuffer(_ signalDataBuffer: UnsafeBufferPointer<Float>) {
        assert(signalDataBuffer.count == inputSignalBufferSize,
               "Input buffer size not matching initialization params!")
        performFFT(input: signalDataBuffer, output: outputFrequencyBinBuffer)
    }

    private func performFFT(input: UnsafeBufferPointer<Float>,
                            output: UnsafeMutableBufferPointer<Float>) {
        let length = inputSignalBufferSize

        // Apply Hann window
        vDSP_vmul(input.baseAddress!, 1,
                  window, 1,
                  windowedInput.baseAddress!, 1,
                  vDSP_Length(length))

        // Convert to split complex format
        var splitComplex = DSPSplitComplex(realp: real.baseAddress!, imagp: imag.baseAddress!)
        windowedInput.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: length) { typeConvertedPtr in
            vDSP_ctoz(typeConvertedPtr, 2, &splitComplex, 1, vDSP_Length(length / 2))
        }

        // Perform FFT
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

        // Normalize
        var scale: Float = 1.0 / Float(length)
        vDSP_vsmul(splitComplex.realp, 1, &scale, splitComplex.realp, 1, vDSP_Length(length / 2))
        vDSP_vsmul(splitComplex.imagp, 1, &scale, splitComplex.imagp, 1, vDSP_Length(length / 2))

        // Compute magnitudes
        vDSP_zvmags(&splitComplex, 1, output.baseAddress!, 1, vDSP_Length(length / 2))
        vvsqrtf(output.baseAddress!, output.baseAddress!, [Int32(length / 2)])
    }
}
