//
//  TemplateEditCommand.swift
//  
//
//  Created by Mikhail Apurin on 09.05.2022.
//

import ArgumentParser
import Foundation
import NewIcon

struct TemplateEditCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit a template file."
    )
    
    @Argument(
        help: "Path to a template file.",
        completion: .file()
    )
    var path: String
    
    @MainActor func run() async throws {
        try NewIcon.editTemplate(
            url: try path.resolvedAsRelativePath,
            textOutput: { print($0) }
        )
        
        print("Removed temporary swift package.")
    }
}
