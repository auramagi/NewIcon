//
//  ResetCommand.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import AppKit
import ArgumentParser
import Foundation

struct ResetCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Revert to the original icon."
    )
    
    @Argument(
        help: "Path to the file or directory.",
        completion: .file()
    )
    var path: String
    
    func run() throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw "File does not exist"
        }
        
        NSWorkspace.shared.setIcon(nil, forFile: path)
    }
}
