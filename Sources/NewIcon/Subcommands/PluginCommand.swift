//
//  PluginCommand.swift
//  
//
//  Created by Mikhail Apurin on 12.05.2022.
//

import ArgumentParser
import Foundation

struct PluginCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "plugin",
        abstract: "Manage template plugins.",
        subcommands: [PluginListCommand.self, PluginInstallCommand.self, PluginUninstallCommand.self]
    )
}

struct PluginListCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed template plugins."
    )
    
    func run() throws {
        let names = try InstalledPluginsMetadata.load()
            .data
            .map(\.name)
            .sorted()
        
        print("Total installed plugins: \(names.count).")
        names.forEach {
            print("  - \($0)")
        }
        
    }
}

struct PluginInstallCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install a template plugin."
    )
    
    @Argument(
        help: "Path to a template source file.",
        completion: .file()
    )
    var path: String
    
    @Option(
        help: "Custom name."
    )
    var name: String?
    
    @MainActor func run() async throws {
        let fileURL = try path.resolvedAsRelativePath
        let name = name ?? fileURL.deletingPathExtension().lastPathComponent
        guard try InstalledPluginsMetadata.data(name: name) == nil else {
            throw "Plugin with name \(name) already installed."
        }
        let installationURL = try TemplatePlugin.InstallationURL.permanent(name: name)
        try FileManager.default.removeItemIfExists(at: installationURL.url)
        let plugin = try TemplatePlugin(fileURL: fileURL, installationURL: installationURL)
        do {
            let templateImage = try await plugin.build()
            let metadata = PluginMetadata(
                name: name,
                directory: installationURL.url,
                build: templateImage.url
            )
            try InstalledPluginsMetadata.save(metadata)
            try plugin.cleanUp()
            print("Installed \(name)")
        } catch {
            try? plugin.cleanUp(forced: true)
            throw error
        }
    }
}

struct PluginUninstallCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall an installed template plugin."
    )
    
    @Argument(
        help: "Installed template plugin name."
    )
    var name: String
    
    func run() throws {
        guard let metadata = try InstalledPluginsMetadata.data(name: name) else {
            throw "Plugin \(name) not installed."
        }
        
        try InstalledPluginsMetadata.removeData(name: name)
        try FileManager.default.removeItemIfExists(at: metadata.directory)
        print("Plugin \(name) was uninstalled.")
    }
}
