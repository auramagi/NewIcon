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
            try resolvedAsRelativePath()
        }
    }
    
    func resolvedAsRelativePath(fileManager: FileManager = .default, checkExistence: Bool = true) throws -> URL {
        try fileManager.fileURL(resolvingRelativePath: self, checkExistence: checkExistence)
    }
}
