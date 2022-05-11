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
    func build(fileURL: URL?, templateType: String?) async throws -> Template<Input> {
        if let fileURL = fileURL {
            return try await build(fileURL: fileURL, templateType: templateType)
        } else {
            return .init(
                render: { try defaultTemplate($0) },
                cleanUp: { }
            )
        }
    }
    
    private func build(fileURL: URL, templateType: String?) async throws -> Template<Input> {
        let plugin = try TemplatePlugin(fileURL: fileURL)
        do {
            let templateImage = try await plugin.build()
            
            typealias RenderTemplate = @convention(c) (Any, Any) -> Any
            let (templateTypes, renderTemplate) = try templateImage.open(
                isTemplateSymbol: isTemplateSymbol,
                renderTemplateSymbol: renderTemplateSymbol,
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
                    try (renderTemplate(type, $0) as? Result<AnyView, Error>)
                        .unwrapOrThrow("Could not generate SwiftUI view from plugin")
                        .get()
                },
                cleanUp: {
                    do {
                        try plugin.cleanUp()
                    } catch {
                        print("Warning: Error while cleaning up plugin folder.", error)
                    }
                }
            )
        } catch {
            try? plugin.cleanUp()
            throw error
        }
    }
}
