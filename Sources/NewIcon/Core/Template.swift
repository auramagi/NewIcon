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
    }
}

extension Template.Builder {
    func build(
        fileURL: URL,
        useCache: Bool,
        templateType: String?
    ) async throws -> Template<Input> {
        let plugin = try TemplatePlugin(
            fileURL: fileURL,
            installationURL: useCache ? try .permanent(fileURL: fileURL) : try .temporary
        )
        do {
            let templateImage = try await plugin.makeImage()
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
    }
    
    func build<V: View>(builtinTemplate: @escaping (Input) throws -> V) -> Template<Input> {
        .init {
            AnyView(try builtinTemplate($0))
        } cleanUp: {
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
