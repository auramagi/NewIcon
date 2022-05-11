//
//  TemplateImage.swift
//  
//
//  Created by Mikhail Apurin on 12.05.2022.
//

import Foundation

struct TemplateImage {
    let url: URL
    
    func open<RenderTemplate>(
        isTemplateSymbol: String,
        renderTemplateSymbol: String,
        renderTemplateType: RenderTemplate.Type,
        templateType: String?
    ) throws -> (type: Any.Type, renderTemplate: RenderTemplate) {
        guard let pluginHandle = dlopen(url.path, RTLD_NOW) else {
            if let error = dlerror() {
                throw "dlopen error: \(String(cString: error))"
            } else {
                throw "Unknown dlopen error"
            }
        }
        
        typealias IsTemplate = @convention(c) (Any) -> Bool
        let isTemplate = try dlsym(pluginHandle, isTemplateSymbol)
            .map { unsafeBitCast($0, to: (IsTemplate).self) }
            .unwrapOrThrow("Plugin doesn't contain the \(isTemplateSymbol) entry point from TemplateSupport")
        
        let renderTemplate = try dlsym(pluginHandle, renderTemplateSymbol)
            .map { unsafeBitCast($0, to: (RenderTemplate).self) }
            .unwrapOrThrow("Plugin doesn't contain the \(renderTemplateSymbol) entry point from TemplateSupport")
        
        let templateTypes: [Any.Type] = try MachImage(name: url.path)
            .unwrapOrThrow("Did not find plugin image after dlopen")
            .symbols
            .filter { $0.name.hasSuffix("VN") } // is struct type metadata? (see: https://github.com/apple/swift/blob/main/docs/ABI/Mangling.rst)
            .map { unsafeBitCast($0.address, to: Any.Type.self) }
            .filter(isTemplate)
        
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
        
        return (type, renderTemplate)
    }
}
