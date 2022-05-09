//
//  TextCommand.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import AppKit
import ArgumentParser
import Foundation
import SwiftUI

struct TextCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Overlay text over the original icon."
    )
    
    @Argument(
        help: "Path to a file or directory.",
        completion: .file()
    )
    var path: String
    
    @Argument(
        help: "Text to overlay."
    )
    var text: String
    
    @Option(
        name: .shortAndLong,
        help: "An image to use instead of extracting the original icon.",
        completion: .file()
    )
    var image: String?
    
    @Option(
        name: .shortAndLong,
        help: "Path to template file.",
        completion: .file()
    )
    var template: String?
    
    @Option(
        name: .long,
        help: ArgumentHelp(
            "Struct type to use.",
            discussion: "If a template file contains several possible template types, this option specifies which one to use."
        )
    )
    var templateType: String?
    
    @MainActor func run() async throws {
        let fm = FileManager.default
        
        let template = try await prepareTemplate() // Build template before resetting icon to the original
        let icon = try Icon.load(
            target:  try fm.fileURL(resolvingRelativePath: path),
            imageURL: image.map { try fm.fileURL(resolvingRelativePath: $0) }
        )
        
        var error: Error? // Collate errors since we want clean up to always run
        error.catching { try applyTemplate(template, to: icon) }
        error.catching { try icon.cleanUp() }
        error.catching { try template.cleanUp() }
        try error.throwIfPresent()
    }
    
    private func prepareTemplate() async throws -> Template {
        if let template = template {
            let templateURL = try FileManager.default.fileURL(resolvingRelativePath: template)
            return try await buildTemplate(fileURL: templateURL)
        } else {
            return .init(
                render: { AnyView(IconTextView(image: $0, text: $1)) },
                cleanUp: { }
            )
        }
    }
    
    private func buildTemplate(fileURL: URL) async throws -> Template {
        let plugin = try TemplatePlugin(fileURL: fileURL)
        do {
            let templateImage = try await plugin.build()
            
            typealias RenderTemplate = @convention(c) (Any, NSImage, String) -> Any
            let (templateTypes, renderTemplate) = try templateImage.open(
                isTemplateSymbol: "isTemplate",
                renderTemplateSymbol: "renderTemplate",
                renderTemplateType: RenderTemplate.self
            )
            
            let type: Any.Type = try {
                if let templateType = templateType {
                    return try templateTypes
                        .first { "\($0)" == templateType }
                        .unwrapOrThrow("Did not find the type specified with the --template-type option: \(templateType)")
                    
                } else if templateTypes.count > 1 {
                    throw "Template contains multiple template types, choose which one to use with the --template-type option. Available types: \(templateTypes.map { "\($0)" })"
                } else if let type = templateTypes.first {
                    return type
                } else {
                    throw "Plugin doesn't contain a template struct"
                }
            }()
            
            return .init(
                render: {
                    try (renderTemplate(type, $0, $1) as? AnyView)
                        .unwrapOrThrow("Could not generate SwiftUI view from plugin")
                },
                cleanUp: {
                    try plugin.cleanUp()
                }
            )
        } catch {
            try? plugin.cleanUp()
            throw error
        }
    }
    
    private func applyTemplate(_ template: Template, to icon: Icon) throws {
        let renderedTemplate = try template.render(icon.image, text)
        try icon.replace(with: renderedTemplate)
    }
}

private extension TextCommand {
    struct Template {
        let render: (_ image: NSImage, _ text: String) throws -> AnyView
        let cleanUp: () throws -> Void
    }
}

// MARK: - Default template

// Default template. Synced to PluginTemplate/Template-Template-swift.template
private struct IconTextView: View {
    let image: NSImage

    let text: String

    // Expect size to be 1024x1024
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .overlay(
                Text(text)
                    .font(.system(size: 160, weight: .bold, design: .rounded))
                    .colorScheme(.dark)
                    .minimumScaleFactor(0.1)
                    .multilineTextAlignment(.center)
                    .frame(width: 612)
                    .frame(maxHeight: 189)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.black.opacity(0.56))
                    )
                    .alignmentGuide(VerticalAlignment.center) { $0.height / 2 - 184 }
            )
    }
}
