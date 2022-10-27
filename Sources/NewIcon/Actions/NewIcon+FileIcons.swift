//
//  NewIcon+FileIcons.swift
//  
//
//  Created by Mikhail Apurin on 2022/10/27.
//

import AppKit
import Foundation

public extension NewIcon {
    /// Set a file icon
    /// - Parameters:
    ///   - icon: New icon image
    ///   - url: Target file or folder URL
    static func setIcon(_ icon: NSImage, forFile url: URL) {
        assert(url.isFileURL)
        NSWorkspace.shared.setIcon(icon, forFile: url.path)
    }

    /// Reset a file icon
    /// - Parameter url: Target file or folder URL
    static func resetIcon(forFile url: URL) {
        assert(url.isFileURL)
        NSWorkspace.shared.setIcon(nil, forFile: url.path)
    }
    
    /// Is the file icon the default one or was it changed?
    /// - Parameter url: Target file or folder URL
    static func iconIsChanged(forFile url: URL) -> Bool {
        assert(url.isFileURL)
        return FileManager.default.fileExists(
            atPath: url.appendingPathComponent("Icon\r").path
        )
    }
}
