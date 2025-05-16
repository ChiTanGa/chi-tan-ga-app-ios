//
//  ShaderType.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

enum ShaderType: String, CaseIterable, Identifiable {
    case dream
    case cloud
    case osciloscope
    case frequencyAnalyser

    var id: String { self.rawValue }
    var vertexFunctionName: String {
        switch self {
        case .dream: return "vertex_dream"
        case .cloud: return "vertex_cloud"
        case .osciloscope: return "vertex_osciloscope"
        case .frequencyAnalyser: return "vertex_frequency_analyser"
        }
    }

    var fragmentFunctionName: String {
        switch self {
        case .dream: return "fragment_dream"
        case .cloud: return "fragment_cloud"
        case .osciloscope: return "fragment_osciloscope"
        case .frequencyAnalyser: return "fragment_frequency_analyser"
        }
    }
}
