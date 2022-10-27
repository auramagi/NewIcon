//
//  NewIcon+Text.swift
//  
//
//  Created by Mikhail Apurin on 2022/10/27.
//

import AppKit
import ArgumentParser
import Foundation
import SwiftUI

public extension NewIcon {
    /// Render text over an icon and either save it as an image file or set as a file icon
    /// - Parameters:
    ///   - text: Text to apply over the icon
    ///   - output: Where to save the rendered image
    ///   - iconSource: Base icon source
    @MainActor static func applyText(
        _ text: String,
        to output: Output,
        iconSource: IconSource
    ) async throws {
        let template = try await buildTemplate(text: text)
        defer { template.cleanUp() }

        let icon = try Icon.load(source: iconSource)

        do {
            let data = try JSONEncoder().encode(text)
            let renderedTemplate = try template.render((icon.image, data))
            try icon.apply(renderedTemplate, to: output)
        } catch {
            icon.cleanUp()
            throw error
        }
    }
}

private extension NewIcon {
    typealias Input = (NSImage, Data?)

    static var builder = Template.Builder(
        isTemplateSymbol: "isImageTemplate",
        renderTemplateSymbol: "renderImageTemplate",
        renderTemplateInputType: Input.self
    )

    static func buildTemplate(text: String) async throws -> Template<Input> {
        builder.build {
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
