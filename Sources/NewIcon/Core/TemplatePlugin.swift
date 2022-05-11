//
//  TemplatePlugin.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import AppKit
import Foundation

struct TemplatePlugin {
    let installationURL: InstallationURL
    
    let package: URL
    
    let templateFile: URL
    
    init(fileURL: URL, installationURL: InstallationURL) throws {
        let bundle = try Bundle.locateResourcesBundle()
        
        func template(_ name: String, renamedTo newName: String) throws -> FileWrapper {
            let wrapper = try bundle.url(forResource: name, withExtension: "template")
                .map { try FileWrapper(url: $0) }
                .unwrapOrThrow("Could not locate template resource: \(name)")
            wrapper.preferredFilename = newName
            return wrapper
        }
        
        try FileWrapper(directoryWithFileWrappers: [
            "Template": FileWrapper(directoryWithFileWrappers: [
                "Package.swift": try template("PluginTemplate/Template-Package-swift", renamedTo: "Package.swift"),
                "Sources": FileWrapper(directoryWithFileWrappers: [
                    "Template": FileWrapper(directoryWithFileWrappers: [
                        "Template.swift": try FileWrapper(url: fileURL),
                    ]),
                ]),
                "TemplateSupport": FileWrapper(directoryWithFileWrappers: [
                    "Package.swift": try template("PluginTemplate/TemplateSupport-Package-swift", renamedTo: "Package.swift"),
                    "Sources": FileWrapper(directoryWithFileWrappers: [
                        "TemplateSupport": FileWrapper(directoryWithFileWrappers: [
                            "TemplateSupport.swift": try template("PluginTemplate/TemplateSupport-TemplateSupport-swift", renamedTo: "TemplateSupport.swift"),
                        ]),
                    ]),
                ]),
            ]),
        ]).write(
            to: installationURL.url,
            originalContentsURL: nil
        )
        
        self.installationURL = installationURL
        self.package = installationURL.url.appendingPathComponent("Template", isDirectory: true)
        self.templateFile = URL(fileURLWithPath: "Sources/Template/\(fileURL.lastPathComponent)", relativeTo: package)
    }
    
    func showInFinder() {
        NSWorkspace.shared.selectFile(package.path, inFileViewerRootedAtPath: "")
    }
    
    func openInXcode() throws {
        try Shell.executeSync("xed \(package.path)")
    }
    
    func build() async throws -> TemplateImage {
        // Build with release configuration but set -Onone optimization so that the non-public types don't get stripped as dead code
        try await Shell.executeWithStandardOutput("swift build -c release -Xswiftc -Onone", currentDirectory: package)
        let binPath = try Shell.executeSync("swift build -c release --show-bin-path", currentDirectory: package)
            .unwrapOrThrow("Could not get package build bin path")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return .init(url: URL(fileURLWithPath: binPath).appendingPathComponent("libTemplate.dylib"))
    }
    
    func cleanUp() throws {
        guard installationURL.isTemporary else { return }
        try FileManager.default.removeItem(at: installationURL.url)
    }
}

struct TemplateImage {
    let url: URL
    
    func open<RenderTemplate>(
        isTemplateSymbol: String,
        renderTemplateSymbol: String,
        renderTemplateType: RenderTemplate.Type
    ) throws -> (types: [Any.Type], renderTemplate: RenderTemplate) {
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
        
        return (templateTypes, renderTemplate)
    }
}

extension TemplatePlugin {
    struct InstallationURL {
        let url: URL
        
        let isTemporary: Bool
    
        static var commonPath = "~/.new-icon"
        
        static var temporary: Self {
            get throws {
                .init(
                    url: try commonPath
                        .resolvedAsRelativePath(checkExistence: false)
                        .appendingPathComponent("temp", isDirectory: true)
                        .creatingDirectoryIfNeeded
                        .appendingPathComponent(ProcessInfo().globallyUniqueString),
                    isTemporary: true
                )
                
            }
        }
        
        static var permanentCommonURL: URL {
            get throws {
                try commonPath
                    .resolvedAsRelativePath(checkExistence: false)
                    .appendingPathComponent("plugins", isDirectory: true)
                    .creatingDirectoryIfNeeded
            }
        }
        
        static func permanent(name: String) throws -> Self {
            .init(
                url: try permanentCommonURL
                    .appendingPathComponent(name),
                isTemporary: false
            )
        }
    }
}
