//
//  ResetCommand.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import ArgumentParser
import Foundation
import NewIcon

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
        let fileURL = try path.resolvedAsRelativePath

        NewIcon.resetIcon(forFile: fileURL)
        
        print("Reset icon for", fileURL)
    }
}
