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
    static let configuration = CommandConfiguration(
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
        help: "Path to write out the resulting image instead of changing the icon.",
        completion: .file()
    )
    var output: String?
    
    private typealias Input = (NSImage, Data?)
    
    private static var builder = Template.Builder(
        isTemplateSymbol: "isImageTemplate",
        renderTemplateSymbol: "renderImageTemplate",
        renderTemplateInputType: Input.self
    )
    
    @MainActor func run() async throws {
        let template = try await buildTemplate()
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
        
        if output != nil {
            print("Image was successfully saved.")
        } else {
            print("Icon was successfully changed.")
        }
    }
    
    private func buildTemplate() async throws -> Template<Input> {
        Self.builder.build {
            TextOverlay(
                icon: $0.0,
                content: text
            )
        }
    }
}

/// Overlay text with a fixed-width semi-translucent background.
/// This is also the sample template we provide with `template init` via PluginTemplate/Template-Template-swift.template
private struct TextOverlay: View {
    let icon: NSImage

    let content: String

    // Expect size to be 1024x1024
    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .scaledToFit()
            .overlay(
                Text(content)
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
