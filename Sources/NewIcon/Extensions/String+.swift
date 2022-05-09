//
//  String+.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import Foundation

extension String: Error { }

extension String {
    var resolvedAsRelativePath: URL {
        get throws {
            try resolvedAsRelativePath(fileManager: .default)
        }
    }
    
    func resolvedAsRelativePath(fileManager: FileManager) throws -> URL {
        try fileManager.fileURL(resolvingRelativePath: self)
    }
}
