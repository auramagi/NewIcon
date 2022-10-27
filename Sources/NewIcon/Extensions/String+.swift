//
//  String+.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import Foundation

extension String: Error { }

extension String {
    public var resolvedAsRelativePath: URL {
        get throws {
            try resolvedAsRelativePath()
        }
    }
    
    public func resolvedAsRelativePath(fileManager: FileManager = .default, checkExistence: Bool = true) throws -> URL {
        try fileManager.fileURL(resolvingRelativePath: self, checkExistence: checkExistence)
    }
    
    func base64EncodedSHA256Hash() throws -> String {
        try data(using: .utf8)
            .unwrapOrThrow("Can't convert string to .utf8: \(self)")
            .base64EncodedSHA256Hash()
    }
}
