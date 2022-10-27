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
import NewIcon

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
    
    @MainActor func run() async throws {
        try await NewIcon.applyText(
            text,
            to: try commandOutput,
            iconSource: try iconSource
        )

        if output != nil {
            print("Image was successfully saved.")
        } else {
            print("Icon was successfully changed.")
        }
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
