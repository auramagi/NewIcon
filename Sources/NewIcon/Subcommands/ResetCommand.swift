//
//  ResetCommand.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import AppKit
import ArgumentParser
import Foundation

struct ResetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Revert to the original icon."
    )
    
    @Argument(
        help: "Path to a file or directory.",
        completion: .file()
    )
    var path: String
    
    @MainActor func run() async throws {
        let targetFilePath = try path.resolvedAsRelativePath.path
        
        NSWorkspace.shared.setIcon(nil, forFile: targetFilePath)
        
        print("Reset icon for", targetFilePath)
    }
}
