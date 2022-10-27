//
//  TemplateInitCommand.swift
//  
//
//  Created by Mikhail Apurin on 31.05.2022.
//

import ArgumentParser
import Foundation
import NewIcon

struct TemplateInitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a sample template file."
    )
    
    @MainActor func run() async throws {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Template.swift")

        try NewIcon.copyDefaultTemplate(to: fileURL)
                
        print("Saved a sample template file to", fileURL.path)
    }
}
