//
//  Template.swift
//  
//
//  Created by Mikhail Apurin on 10.05.2022.
//

import Foundation
import SwiftUI

struct Template<Input> {
    let render: (Input) throws -> AnyView
    
    let cleanUp: () -> Void
}

extension Template {
    struct Builder {
        let isTemplateSymbol: String
        let renderTemplateSymbol: String
        let renderTemplateInputType: Input.Type
        let defaultTemplate: (Input) throws -> AnyView
    }
}

extension Template.Builder {
    func build(
        plugin: String?,
        fileURL: URL?,
        installationURL: TemplatePlugin.InstallationURL,
        templateType: String?
    ) async throws -> Template<Input> {
        if let plugin = plugin {
            let metadata = try InstalledPluginsMetadata.data(name: plugin)
                .unwrapOrThrow("Plugin \(plugin) not installed")
            let templateImage = TemplateImage(url: metadata.build)
            return build(templateImage: templateImage, templateType: templateType) { }
        } else if let fileURL = fileURL {
            let plugin = try TemplatePlugin(fileURL: fileURL, installationURL: installationURL)
            do {
                let templateImage = try await plugin.build()
                return build(templateImage: templateImage, templateType: templateType) {
                    do {
                        try plugin.cleanUp()
                    } catch {
                        print("Warning: Error while cleaning up plugin folder.", error)
                    }
                }
            } catch {
                try? plugin.cleanUp()
                throw error
            }
        } else {
            return .init {
                try defaultTemplate($0)
            } cleanUp: {
            }
        }
    }
    
    func build(templateImage: TemplateImage, templateType: String?, cleanup: @escaping () -> Void) -> Template {
        .init {
            try run(templateImage: templateImage, templateType: templateType, input: $0)
        } cleanUp: {
            cleanup()
        }
    }
    
    private func run(templateImage: TemplateImage, templateType: String?, input: Input) throws -> AnyView {
        typealias RenderTemplate = @convention(c) (Any, Any) -> Any
        let (type, renderTemplate) = try templateImage.open(
            isTemplateSymbol: isTemplateSymbol,
            renderTemplateSymbol: renderTemplateSymbol,
            renderTemplateType: RenderTemplate.self,
            templateType: templateType
        )
        return try (renderTemplate(type, input) as? Result<AnyView, Error>)
            .unwrapOrThrow("Could not generate SwiftUI view from plugin")
            .get()
    }
}
