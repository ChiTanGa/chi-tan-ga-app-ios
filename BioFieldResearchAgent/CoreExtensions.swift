//
//  CoreExtensions.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 07.05.2025.
//

extension Int {
    var isPowerOfTwo: Bool {
        return self > 0 && (self & (self - 1)) == 0
    }
}
