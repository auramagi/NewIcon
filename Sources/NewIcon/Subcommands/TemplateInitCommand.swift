//
//  TemplateInitCommand.swift
//  
//
//  Created by Mikhail Apurin on 31.05.2022.
//

import ArgumentParser
import Foundation

struct TemplateInitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a sample template file."
    )
    
    @MainActor func run() async throws {
        try Bundle.locateResourcesBundle()
            .template("PluginTemplate/Template-Template-swift")
            .write(
                to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("Template.swift")
                ,
                originalContentsURL: nil
            )
    }
}
