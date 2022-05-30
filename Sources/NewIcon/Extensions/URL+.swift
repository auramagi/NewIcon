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
    
    func pathStableBase64EncodedSHA256HashString() throws -> String {
        let data = try Data(contentsOf: self)
        return """
               \(try path.base64EncodedSHA256Hash())\
               \(data.count)\
               \(data.base64EncodedSHA256Hash())
               """
    }
}
