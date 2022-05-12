//
//  URL+.swift
//  
//
//  Created by Mikhail Apurin on 12.05.2022.
//

import Foundation

extension URL {
    var creatingDirectoryIfNeeded: URL {
        get throws {
            try creatingDirectoryIfNeeded()
        }
    }
    
    func creatingDirectoryIfNeeded(fileManager: FileManager = .default, withIntermediateDirectories createIntermediates: Bool = true) throws -> URL {
        try fileManager.createDirectoryIfNeeded(at: self, withIntermediateDirectories: createIntermediates)
        return self
    }
}
