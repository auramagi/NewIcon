//
//  TemplateIconCommand.swift
//  
//
//  Created by Mikhail Apurin on 30.05.2022.
//

import ArgumentParser
import AppKit
import SwiftUI

struct TemplateIconCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "icon",
        abstract: "Render a template with an icon and some content."
    )

    @Option(
        name: .shortAndLong,
        help: "Path to a template file.",
        completion: .file()
    )
    var template: String?
    
    @Argument(
        help: "Path to a file or directory.",
        completion: .file()
    )
    var path: String
    
    @Argument(
        help: "Content to pass to the template."
    )
    var text: String?
    
    @Option(
        name: .shortAndLong,
        help: "An image to use instead of extracting the original icon.",
        completion: .file()
    )
    var image: String?
    
    @Option(
        name: .long,
        help: ArgumentHelp(
            "Struct type to use.",
            discussion: "If a template contains several possible template types, this option specifies which one to use."
        )
    )
    var templateType: String?
    
    @Option(
        name: .shortAndLong,
        help: "Path to write out the resulting image instead of changing the icon.",
        completion: .file()
    )
    var output: String?
    
    private static var builder = Template.Builder(
        isTemplateSymbol: "isImageTemplate",
        renderTemplateSymbol: "renderImageTemplate",
        renderTemplateInputType: (NSImage, Data).self,
        defaultTemplate: { _ in throw "Could not render provided template" }
    )
    
    @MainActor func run() async throws {
        let template = try await Self.builder.build(
            plugin: nil,
            fileURL: try template?.resolvedAsRelativePath,
            installationURL: try TemplatePlugin.InstallationURL.temporary,
            templateType: templateType
        )
        defer { template.cleanUp() }
        
        let icon = try Icon.load(
            target:  try path.resolvedAsRelativePath,
            imageURL: try image?.resolvedAsRelativePath
        )
        
        do {
            let data = try JSONEncoder().encode(text)
            let renderedTemplate = try template.render((icon.image, data))
            try icon.apply(renderedTemplate, to: try output?.resolvedAsRelativePath(checkExistence: false))
        } catch {
            icon.cleanUp()
            throw error
        }
    }
}
