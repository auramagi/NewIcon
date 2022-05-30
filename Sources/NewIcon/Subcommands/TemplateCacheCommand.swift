//
//  TemplateCacheCommand.swift
//  
//
//  Created by Mikhail Apurin on 31.05.2022.
//

import ArgumentParser
import Foundation

struct TemplateCacheCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cache",
        abstract: "Manage template file builds cache.",
        subcommands: [
            TemplateCacheClearCommand.self,
        ]
    )
}

struct TemplateCacheClearCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Manage template file builds cache."
    )
    
    @MainActor func run() async throws {
        try FileManager.default
            .removeItemIfExists(at: TemplatePlugin.InstallationURL.permanentCommonURL)
        
        print("File builds cache cleared.")
    }
}
