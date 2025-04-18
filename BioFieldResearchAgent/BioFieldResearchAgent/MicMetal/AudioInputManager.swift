//
//  AudioInputManager.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import AVFoundation

class AudioInputManager {
    private let engine = AVAudioEngine()
    var onAmplitudeUpdate: ((Float) -> Void)?

    init() {
        #if os(iOS)
        configureAudioSession()
        #endif

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        // Optional: Defensive check
        guard format.channelCount > 0 else {
            print("Audio format has zero channels — cannot install tap.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            let level = self.computeAmplitude(buffer: buffer)
            print("Amplitude: \(level)")
            DispatchQueue.main.async {
                self.onAmplitudeUpdate?(level)
            }
        }

        do {
            try engine.start()
        } catch {
            print("❌ Error starting audio engine: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("⚠️ Error setting up audio session: \(error)")
        }
    }
    #endif
    
    private func computeAmplitude(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }

        let frameLength = Int(buffer.frameLength)
        let channelDataPointer = UnsafeBufferPointer(start: channelData, count: frameLength)

        let rms = sqrt(channelDataPointer.reduce(0) { $0 + $1 * $1 } / Float(frameLength))
        return min(max(rms * 20, 0), 1)
    }
}
