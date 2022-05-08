//
//  FileManager+.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation

extension FileManager {
    func fileURL(resolvingRelativePath path: String) throws -> URL {
        let url = URL(
            fileURLWithPath: (path as NSString).expandingTildeInPath,
            relativeTo: URL(fileURLWithPath: currentDirectoryPath)
        )
        guard fileExists(atPath: url.path) else {
            throw "File does not exist at path \(url.path)"
        }
        return url
    }
}
