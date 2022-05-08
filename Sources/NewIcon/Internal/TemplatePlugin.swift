//
//  TemplatePlugin.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation
import AppKit

struct TemplatePlugin {
    let temporaryDirectory: URL
    
    let package: URL
    
    init() throws {
        func template(name: String, renamedTo newName: String) throws -> FileWrapper {
            let wrapper = try Bundle.module.url(forResource: name, withExtension: "template")
                .map { try FileWrapper(url: $0) }
                .unwrapOrThrow("Can't locate template resource: \(name)")
            wrapper.preferredFilename = newName
            return wrapper
        }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString, isDirectory: true)
        let package = temporaryDirectory.appendingPathComponent("Template", isDirectory: true)
        
        try FileWrapper(directoryWithFileWrappers: [
            "Template": FileWrapper(directoryWithFileWrappers: [
                "Package.swift": try template(name: "PluginTemplate/Template-Package-swift", renamedTo: "Package.swift"),
                "Sources": FileWrapper(directoryWithFileWrappers: [
                    "Template": FileWrapper(directoryWithFileWrappers: [
                        "Template.swift": try template(name: "PluginTemplate/Template-Template-swift", renamedTo: "Template.swift"),
                    ]),
                ]),
                "TemplateSupport": FileWrapper(directoryWithFileWrappers: [
                    "Package.swift": try template(name: "PluginTemplate/TemplateSupport-Package-swift", renamedTo: "Package.swift"),
                    "Sources": FileWrapper(directoryWithFileWrappers: [
                        "TemplateSupport": FileWrapper(directoryWithFileWrappers: [
                            "TemplateSupport.swift": try template(name: "PluginTemplate/TemplateSupport-TemplateSupport-swift", renamedTo: "TemplateSupport.swift"),
                        ]),
                    ]),
                ]),
            ]),
        ]).write(
            to: temporaryDirectory,
            originalContentsURL: nil
        )
        
        self.temporaryDirectory = temporaryDirectory
        self.package = package
    }
    
    func showInFinder() {
        NSWorkspace.shared.selectFile(package.path, inFileViewerRootedAtPath: "")
    }
    
    func openInXcode() {
        Shell.execute(path: "xed", command: package.path, pipe: Pipe())
    }
    
    func cleanUp() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
    }
}
