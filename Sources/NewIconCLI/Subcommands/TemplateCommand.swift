//
//  TemplateCommand.swift
//  
//
//  Created by Mikhail Apurin on 30.05.2022.
//

import ArgumentParser
import Foundation
import NewIcon

struct TemplateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "template",
        abstract: "Render a custom SwiftUI template.",
        subcommands: [
            TemplateInitCommand.self,
            TemplateEditCommand.self,
            TemplateCacheCommand.self,
            TemplateIconCommand.self,
        ]
    )
}
