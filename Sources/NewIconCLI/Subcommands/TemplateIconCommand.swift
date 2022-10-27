//
//  TemplateIconCommand.swift
//  
//
//  Created by Mikhail Apurin on 30.05.2022.
//

import ArgumentParser
import AppKit
import SwiftUI
import NewIcon

struct TemplateIconCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "icon",
        abstract: "Render a template with an icon and some content."
    )

    @Argument(
        help: "Path to a template file.",
        completion: .file()
    )
    var template: String
    
    @Argument(
        help: "Path to a file or directory.",
        completion: .file()
    )
    var path: String
    
    @Argument(
        help: "Content to pass to the template."
    )
    var content: String?
    
    @Option(
        name: .long,
        help: ArgumentHelp(
            "Struct type to use.",
            discussion: "If a template contains several possible template types, this option specifies which one to use."
        )
    )
    var templateType: String?
    
    @Flag(
        name: .long,
        help: "Don't cache template file build."
    )
    var noUseCache = false
    
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
    
    @MainActor func run() async throws {
        try await NewIcon.applyTemplate(
            url: try template.resolvedAsRelativePath,
            to: try commandOutput,
            iconSource: try iconSource,
            content: content,
            templateType: templateType,
            noUseCache: noUseCache
        )
        
        print("Template was successfully rendered.")
    }

    private var iconSource: NewIcon.IconSource {
        get throws {
            if let image {
                return .imageFile(try image.resolvedAsRelativePath)
            } else {
                return .fileIcon(try path.resolvedAsRelativePath)
            }
        }
    }

    private var commandOutput: NewIcon.Output {
        get throws {
            if let output {
                return .imageFile(try output.resolvedAsRelativePath(checkExistence: false))
            } else {
                return .fileIcon(try path.resolvedAsRelativePath)
            }
        }
    }
}
