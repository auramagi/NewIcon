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
    
    private static var builder = Template.Builder(
        isTemplateSymbol: "isTemplate",
        renderTemplateSymbol: "renderTemplate",
        renderTemplateInputType: (NSImage, String).self,
        defaultTemplate: { AnyView(IconTextView(image: $0.0, text: $0.1)) }
    )
    
    @MainActor func run() async throws {
        let fm = FileManager.default
        
        // Build template before resetting icon to the original
        let template = try await Self.builder.build(
            fileURL: template.map { try fm.fileURL(resolvingRelativePath: $0) },
            templateType: templateType
        )
        defer { template.cleanUp() }
        
        let icon = try Icon.load(
            target:  try fm.fileURL(resolvingRelativePath: path),
            imageURL: image.map { try fm.fileURL(resolvingRelativePath: $0) }
        )
        defer { icon.cleanUp() }
        
        let renderedTemplate = try template.render((icon.image, text))
        try icon.replace(with: renderedTemplate)
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
