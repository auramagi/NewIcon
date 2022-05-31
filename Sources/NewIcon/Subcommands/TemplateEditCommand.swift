//
//  TemplateEditCommand.swift
//  
//
//  Created by Mikhail Apurin on 09.05.2022.
//

import ArgumentParser
import Foundation

struct TemplateEditCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit a template file."
    )
    
    @Argument(
        help: "Path to a template file.",
        completion: .file()
    )
    var path: String
    
    @MainActor func run() async throws {
        let fileURL = try path.resolvedAsRelativePath
        let plugin = try TemplatePlugin(fileURL: fileURL, installationURL: TemplatePlugin.InstallationURL.temporary)
        try plugin.copyFiles()
        
        printExplanation(fileURL: fileURL, plugin: plugin)
        
        try plugin.openInXcode()
        
        // Monitor for changes
        let folderDescriptor = open(plugin.templateFile.deletingLastPathComponent().path, O_EVTONLY)
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: folderDescriptor, eventMask: .write)
        source.setEventHandler { saveChanges(original: fileURL, temporary: plugin.templateFile) }
        source.setCancelHandler { close(folderDescriptor) }
        source.resume()
        
        // Wait for user input
        _ = readLine()
        
        // Flush changes and clean up temporary folders if needed
        source.cancel()
        saveChanges(original: fileURL, temporary: plugin.templateFile)
        try plugin.cleanUp()
        
        print("Removed temporary swift package.")
    }
    
    func printExplanation(fileURL: URL, plugin: TemplatePlugin) {
        print("📝 Editing \(fileURL.lastPathComponent)")
        print("The template file will be opened in a temporary swift package.")
        print("Any changes to \(plugin.templateFile.relativePath) in this package will be saved over to the original file.")
        print("\t- Temporary: \(plugin.templateFile.path)")
        print("\t- Original: \(fileURL.path)")
        print("Press the return key to stop monitoring for changes and delete the temporary package.")
    }
    
    func saveChanges(original: URL, temporary: URL) {
        do {
            try copyFileContent(from: temporary, to: original)
        } catch {
            print(error)
        }
    }
    
    func copyFileContent(from target: URL, to destination: URL) throws {
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
