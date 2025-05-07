//
//  SignalProcessor.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 07.05.2025.
//

protocol SignalProcessor {
    func processIncomingAudioBuffer(_ signalDataBuffer: UnsafeBufferPointer<Float>)
}
