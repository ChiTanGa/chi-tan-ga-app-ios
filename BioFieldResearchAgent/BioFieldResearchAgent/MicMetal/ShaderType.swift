//
//  ShaderType.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

enum ShaderType: String, CaseIterable, Identifiable {
    case dream
    case cloud

    var id: String { self.rawValue }
    var vertexFunctionName: String {
        switch self {
        case .dream: return "basic_vertex"
        case .cloud: return "vertex_cloud"
        }
    }

    var fragmentFunctionName: String {
        switch self {
        case .dream: return "basic_fragment"
        case .cloud: return "fragment_cloud"
        }
    }
}
