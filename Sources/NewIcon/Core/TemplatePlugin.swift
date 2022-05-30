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
    
    let source: URL
    
    let package: URL
    
    let templateFile: URL
    
    init(fileURL: URL, installationURL: InstallationURL) throws {
        self.installationURL = installationURL
        self.source = fileURL
        self.package = installationURL.url.appendingPathComponent("Template", isDirectory: true)
        self.templateFile = URL(fileURLWithPath: "Sources/Template/\(fileURL.lastPathComponent)", relativeTo: package)
    }
    
    func showInFinder() {
        NSWorkspace.shared.selectFile(package.path, inFileViewerRootedAtPath: "")
    }
    
    func openInXcode() throws {
        try Shell.executeSync("xed \(package.path)")
    }
    
    func makeImage() async throws -> TemplateImage {
        if let cached = try? cachedImage() {
            return cached
        }
        try cleanUp(forced: true)
        try copyFiles()
        return try await build()
    }
    
    private func copyFiles() throws {
        let bundle = try Bundle.locateResourcesBundle()
        
        try FileWrapper(directoryWithFileWrappers: [
            "Template": FileWrapper(directoryWithFileWrappers: [
                "Package.swift": try bundle.template("PluginTemplate/Template-Package-swift", renamedTo: "Package.swift"),
                "Sources": FileWrapper(directoryWithFileWrappers: [
                    "Template": FileWrapper(directoryWithFileWrappers: [
                        "Template.swift": try FileWrapper(url: source),
                    ]),
                ]),
                "TemplateSupport": FileWrapper(directoryWithFileWrappers: [
                    "Package.swift": try bundle.template("PluginTemplate/TemplateSupport-Package-swift", renamedTo: "Package.swift"),
                    "Sources": FileWrapper(directoryWithFileWrappers: [
                        "TemplateSupport": FileWrapper(directoryWithFileWrappers: [
                            "TemplateSupport.swift": try bundle.template("PluginTemplate/TemplateSupport-TemplateSupport-swift", renamedTo: "TemplateSupport.swift"),
                        ]),
                    ]),
                ]),
            ]),
        ]).write(
            to: installationURL.url,
            originalContentsURL: nil
        )
    }
    
    private func build() async throws -> TemplateImage {
        // Build with release configuration but set -Onone optimization so that the non-public types don't get stripped as dead code
        try await Shell.executeWithStandardOutput("swift build -c release -Xswiftc -Onone", currentDirectory: package)
        let binPath = try Shell.executeSync("swift build -c release --show-bin-path", currentDirectory: package)
            .unwrapOrThrow("Could not get package build bin path")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let dylib = URL(fileURLWithPath: binPath).appendingPathComponent("libTemplate.dylib")
        try Metadata.encoder.encode(
            Metadata(
                version: Metadata.currentVersion,
                source: source,
                dylib: dylib
            )
        )
        .write(to: installationURL.metadata, options: .atomic)
        return .init(url: dylib)
    }
    
    private func cachedImage() throws -> TemplateImage {
        guard FileManager.default.fileExists(atPath: installationURL.url.path) else { throw "No cache" }
        let metadata = try Metadata.decoder
            .decode(
                Metadata.self,
                from: try Data(contentsOf: installationURL.metadata)
            )
        guard FileManager.default.fileExists(atPath: metadata.dylib.path) else { throw "dylib missing" }
        return .init(url: metadata.dylib)
    }
    
    func cleanUp(forced: Bool = false) throws {
        guard forced || installationURL.isTemporary else { return }
        try FileManager.default.removeItemIfExists(at: installationURL.url)
    }
}

extension TemplatePlugin {
    struct InstallationURL {
        let url: URL
        
        let isTemporary: Bool
    }
}

extension TemplatePlugin.InstallationURL {
    var metadata: URL {
        url.appendingPathComponent("metadata.json")
    }
    
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
                .appendingPathComponent("cache", isDirectory: true)
                .creatingDirectoryIfNeeded
        }
    }
    
    static func permanent(fileURL: URL) throws -> Self {
        .init(
            url: try permanentCommonURL
                .appendingPathComponent(
                    try fileURL.pathStableBase64EncodedSHA256HashString(),
                    isDirectory: true
                ),
            isTemporary: false
        )
    }
}

extension TemplatePlugin {
    struct Metadata: Codable {
        let version: Int
        
        let source: URL
        
        let dylib: URL
    }
}

extension TemplatePlugin.Metadata {
    static var currentVersion = 1
    
    static var encoder: JSONEncoder { .init() }
    
    static var decoder: JSONDecoder { .init() }
}
