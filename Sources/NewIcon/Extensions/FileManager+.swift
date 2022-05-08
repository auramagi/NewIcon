//
//  FileManager+.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation

extension FileManager {
    func fileURL(resolvingRelativePath path: String) -> URL {
        URL(
            fileURLWithPath: (path as NSString).expandingTildeInPath,
            relativeTo: URL(fileURLWithPath: currentDirectoryPath)
        )
    }
}
