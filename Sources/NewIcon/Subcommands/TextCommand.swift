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
        help: "Path to template file",
        completion: .file()
    )
    var template: String?
    
    func run() throws {        
        guard FileManager.default.fileExists(atPath: path) else {
            throw "File does not exist at path \(path)"
        }
        
        let template = try prepareTemplate()

        let workspace = NSWorkspace.shared
        
        let oldIcon = workspace.icon(forFile: path)
        
        workspace.setIcon(nil, forFile: path)
        let originalIcon = workspace.icon(forFile: path)
        
        do {
            let bestRepresentation = try originalIcon.bestRepresentation(for: .infinite, context: nil, hints: [:])
                .unwrapOrThrow("Could not convert the original icon")
            
            let originalIcon = NSImage()
            originalIcon.addRepresentation(bestRepresentation)
            
            let view = try template.render(originalIcon, text)
            let newIcon = try view
                .frame(width: 1024, height: 1024)
                .colorScheme(.light)
                .asNSImage()
            workspace.setIcon(newIcon, forFile: path)
            try template.cleanUp()
        } catch {
            workspace.setIcon(oldIcon, forFile: path)
            try? template.cleanUp()
            throw error
        }
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
            guard let pluginHandle = dlopen(pluginURL.path, RTLD_NOW) else {
                if let error = dlerror() {
                    throw "dlopen error: \(String(cString: error))"
                } else {
                    throw "Unknown dlopen error"
                }
            }
            
            let type = try dlsym(pluginHandle, "$s8Template12IconTextViewVN")
                .map { unsafeBitCast($0, to: Any.Type.self) }
                .unwrapOrThrow("Plugin doesn't contain a template struct")
            
            typealias MakeTemplate = @convention(c) (Any, NSImage, String) -> Any
            let renderTemplate = try dlsym(pluginHandle, "renderTemplate")
                .map { unsafeBitCast($0, to: (MakeTemplate).self) }
                .unwrapOrThrow("Plugin doesn't contain the makeTemplate entry point from TemplateSupport")
            
            return .init(
                render: { i, _ in
                    try (renderTemplate(type, i, "YEE") as? AnyView)
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
