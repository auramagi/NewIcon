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

struct TextCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Overlay text over the original icon."
    )
    
    @Argument(
        help: "Path to the file or directory.",
        completion: .file()
    )
    var path: String
    
    @Argument(
        help: "Text to overlay."
    )
    var text: String
    
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
    
    func run() throws {        
        guard FileManager.default.fileExists(atPath: path) else {
            throw "File does not exist at path \(path)"
        }
        
        // Build template before resetting icon to the original
        let template = try prepareTemplate()

        // Cache old icon
        let workspace = NSWorkspace.shared
        let oldIcon = workspace.icon(forFile: path)
        
        // Reset icon to the original
        workspace.setIcon(nil, forFile: path)
        let originalIcon = workspace.icon(forFile: path)
        
        do {
            // Pick the highest-quality image
            let bestRepresentation = try originalIcon.bestRepresentation(for: .infinite, context: nil, hints: [:])
                .unwrapOrThrow("Could not convert the original icon")
            
            let originalIcon = NSImage()
            originalIcon.addRepresentation(bestRepresentation)
            
            // Render pre-built SwiftUI template
            let view = try template.render(originalIcon, text)
            let newIcon = try view
                .frame(width: 1024, height: 1024)
                .colorScheme(.light)
                .asNSImage()
            
            // Set the new icon
            workspace.setIcon(newIcon, forFile: path)
        } catch {
            // Failed to set the new icon, so return to the cached old one
            workspace.setIcon(oldIcon, forFile: path)
            
            // Clean up temporary folders if needed
            try? template.cleanUp()
            
            // Propagate error
            throw error
        }
        
        // Clean up temporary folders if needed
        try template.cleanUp()
    }
    
    private func prepareTemplate() throws -> Template {
        if let template = template {
            return try buildTemplate()
        } else {
            return .init(
                render: { AnyView(IconTextView(image: $0, text: $1)) },
                cleanUp: { }
            )
        }
    }
    
    private func buildTemplate() throws -> Template {
        let plugin = try TemplatePlugin()
        do {
            let pluginURL = try plugin.build()
            
            typealias RenderTemplate = @convention(c) (Any, NSImage, String) -> Any
            let (templateTypes, renderTemplate) = try pluginURL.open(
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
