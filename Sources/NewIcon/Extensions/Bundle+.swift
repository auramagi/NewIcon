//
//  Bundle+.swift
//  
//
//  Created by Mikhail Apurin on 09.05.2022.
//

import Foundation

extension Bundle {
    /// Locate our resources bundle. Since mint will symlink only the executable to /usr/local/bin,
    /// and Bundle.module expects to find the bundle in the same path as the main executable,
    /// we need to expand the symlink and make the bundle URL by ourselves.
    static func locateResourcesBundle() throws -> Bundle {
        let bundleURL = try Bundle.main.executableURL
            .unwrapOrThrow("Could not executable path")
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
            .appendingPathComponent("NewIcon_NewIcon.bundle")
        
        return try Bundle(url: bundleURL)
            .unwrapOrThrow("Could not open resources bundle at \(bundleURL.path)")
    }
}
