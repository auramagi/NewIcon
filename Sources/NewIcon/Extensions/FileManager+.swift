//
//  FileManager+.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation

extension FileManager {
    func fileURL(resolvingRelativePath path: String, checkExistence: Bool = true) throws -> URL {
        let url = URL(
            fileURLWithPath: (path as NSString).expandingTildeInPath,
            relativeTo: URL(fileURLWithPath: currentDirectoryPath)
        )
        guard !checkExistence || fileExists(atPath: url.path) else {
            throw "File does not exist at path \(url.path)"
        }
        return url
    }
    
    func createDirectoryIfNeeded(at url: URL, withIntermediateDirectories createIntermediates: Bool = true) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: createIntermediates)
        }
    }
}
