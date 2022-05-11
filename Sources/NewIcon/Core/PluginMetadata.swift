//
//  PluginMetadata.swift
//  
//
//  Created by Mikhail Apurin on 12.05.2022.
//

import Foundation

struct PluginMetadata: Codable {
    let name: String
    
    let directory: URL
    
    let build: URL
}

struct InstalledPluginsMetadata: Codable {
    let version: String
    
    var data: [PluginMetadata]
}

extension InstalledPluginsMetadata {
    static var currentVersion: String = "1"
    
    static var url: URL {
        get throws {
            try TemplatePlugin.InstallationURL.permanentCommonURL
                .appendingPathComponent("metadata.json")
        }
    }
    
    static func load() throws -> Self {
        do {
            let data = try Data(contentsOf: url)
            let result = try JSONDecoder().decode(Self.self, from: data)
            return result
        } catch {
            return .init(
                version: currentVersion,
                data: []
            )
        }
    }
    
    static func save(_ data: PluginMetadata) throws {
        guard try self.data(name: data.name) == nil else {
            throw "Plugin \(data.name) is already installed."
        }
        var current = try load()
        current.data.append(data)
        try current.save()
    }
    
    func save() throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: Self.url, options: .atomic)
    }
}

extension InstalledPluginsMetadata {
    static func data(name: String) throws -> PluginMetadata? {
        try load()
            .data
            .first { $0.name == name }
    }
    
    static func removeData(name: String) throws {
        var current = try load()
        guard current.data.contains(where: { $0.name == name }) else {
            throw "Plugin \(name) is not installed."
        }
        current.data = current.data.filter { $0.name != name }
        try current.save()
    }
}
