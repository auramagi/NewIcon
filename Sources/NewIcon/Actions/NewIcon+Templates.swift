//
//  NewIcon+Templates.swift
//  
//
//  Created by Mikhail Apurin on 2022/10/27.
//

import AppKit
import SwiftUI

public extension NewIcon {
    /// Render a SwiftUI template file and either save it as an image file or set as a file icon
    /// - Parameters:
    ///   - fileURL: Template file
    ///   - output: Where to save the rendered image
    ///   - iconSource: Base icon source
    ///   - content: Optional template content
    ///   - templateType: The View type name in the template. Can be nil if the template contains only one View type
    ///   - noUseCache: Whether to skip using the build cache
    @MainActor static func applyTemplate(
        url fileURL: URL,
        to output: Output,
        iconSource: IconSource,
        content: String?,
        templateType: String?,
        noUseCache: Bool
    ) async throws {
        let template = try await Self.builder.build(
            fileURL: fileURL,
            useCache: !noUseCache,
            templateType: templateType
        )
        defer { template.cleanUp() }

        let icon = try Icon.load(source: iconSource)

        do {
            let data: Data?
            if let content = content {
                data = try JSONEncoder().encode(content)
            } else {
                data = nil
            }
            let renderedTemplate = try template.render((icon.image, data))
            try icon.apply(renderedTemplate, to: output)
        } catch {
            icon.cleanUp()
            throw error
        }
    }

    /// Copy the default template file provided with the library to the specified path
    /// - Parameter fileURL: Copy destination
    static func copyDefaultTemplate(to fileURL: URL) throws {
        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            throw "File already exists: \(fileURL.path)"
        }

        try Bundle.locateResourcesBundle()
            .template("PluginTemplate/Template-Template-swift")
            .write(to: fileURL, originalContentsURL: nil)
    }

    /// Open the template file to edit in Xcode
    /// - Parameters:
    ///   - url: Template file
    ///   - textOutput: Output (console log) to print usage explanation and other messages
    static func editTemplate(url: URL, textOutput: @escaping (String) -> Void) throws {
        let plugin = try TemplatePlugin(fileURL: url, installationURL: TemplatePlugin.InstallationURL.temporary)
        try plugin.copyFiles()

        outputExplanation(fileURL: url, plugin: plugin, textOutput: textOutput)

        try plugin.openInXcode()

        // Monitor for changes
        let folderDescriptor = open(plugin.templateFile.deletingLastPathComponent().path, O_EVTONLY)
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: folderDescriptor, eventMask: .write)
        source.setEventHandler { saveChanges(original: url, temporary: plugin.templateFile, textOutput: textOutput) }
        source.setCancelHandler { close(folderDescriptor) }
        source.resume()

        // Wait for user input
        _ = readLine()

        // Flush changes and clean up temporary folders if needed
        source.cancel()
        saveChanges(original: url, temporary: plugin.templateFile, textOutput: textOutput)
        try plugin.cleanUp()
    }

    /// Clear the build cache
    static func clearTemplateCache() throws {
        try FileManager.default
            .removeItemIfExists(at: TemplatePlugin.InstallationURL.permanentCommonURL)
    }
}

public extension NewIcon {
    private typealias Input = (NSImage, Data?)

    private static var builder = Template.Builder(
        isTemplateSymbol: "isIconTemplate",
        renderTemplateSymbol: "renderIconTemplate",
        renderTemplateInputType: Input.self
    )

    private static func outputExplanation(fileURL: URL, plugin: TemplatePlugin, textOutput: (String) -> Void) {
        textOutput("📝 Editing \(fileURL.lastPathComponent)")
        textOutput("The template file will be opened in a temporary swift package.")
        textOutput("Any changes to \(plugin.templateFile.relativePath) in this package will be saved over to the original file.")
        textOutput("\t- Temporary: \(plugin.templateFile.path)")
        textOutput("\t- Original: \(fileURL.path)")
        textOutput("Press the return key to stop monitoring for changes and delete the temporary package.")
    }

    private static func saveChanges(original: URL, temporary: URL, textOutput: (String) -> Void) {
        do {
            try copyFileContent(from: temporary, to: original)
        } catch {
            textOutput(error.localizedDescription)
        }
    }

    private static func copyFileContent(from target: URL, to destination: URL) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: target.path) else { return }
        guard let data = try? Data(contentsOf: target) else {
            throw "Error reading temporary file"
        }

        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            throw "Error overwriting original file"
        }
    }
}
