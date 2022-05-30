//
//  TemplateCommand.swift
//  
//
//  Created by Mikhail Apurin on 30.05.2022.
//

import ArgumentParser

struct TemplateCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "template",
        abstract: "Render a custom SwiftUI template.",
        subcommands: [TemplateIconCommand.self]
    )
}
