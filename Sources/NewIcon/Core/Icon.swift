//
//  Icon.swift
//  
//
//  Created by Mikhail Apurin on 10.05.2022.
//

import AppKit
import Foundation
import SwiftUI

struct Icon {
    let image: NSImage
    
    let cleanUp: () -> Void
    
    func apply(_ renderedTemplate: AnyView, to output: NewIcon.Output) throws {
        let newImage = try renderedTemplate
            .frame(width: 1024, height: 1024)
            .colorScheme(.light)
            .ignoresSafeArea()
            .drawingGroup() // Make SwiftUI rasterize the view first
            .asNSImage()

        switch output {
        case let .fileIcon(fileURL):
            NewIcon.setIcon(newImage, forFile: fileURL)

        case let .imageFile(fileURL):
            try newImage.write(to: fileURL)
        }
    }
}

extension Icon {
    static func load(source: NewIcon.IconSource) throws -> Icon {
        switch source {
        case let .fileIcon(fileURL):
            return try extracted(from: fileURL)

        case let .imageFile(fileURL):
            return try provided(in: fileURL)
        }
    }
    
    static func provided(in fileURL: URL) throws -> Self {
        let image = try NSImage(contentsOf: fileURL)
            .unwrapOrThrow("Could not load image at \(fileURL.path)")
        
        return .init(
            image: image,
            cleanUp: { }
        )
    }
    
    static func extracted(from target: URL) throws -> Self {
        let workspace = NSWorkspace.shared
        
        // Cache old icon
        let oldIcon = workspace.icon(forFile: target.path)
        let cleanUp = { _ = workspace.setIcon(oldIcon, forFile: target.path) }
        
        // Reset icon to the original
        workspace.setIcon(nil, forFile: target.path)
        let originalIcon = workspace.icon(forFile: target.path)
        
        do {
            // Pick the highest-quality image
            let bestRepresentation = try originalIcon.bestRepresentation(for: .infinite, context: nil, hints: [:])
                .unwrapOrThrow("Could not convert the original icon")
            
            let originalIcon = NSImage()
            originalIcon.addRepresentation(bestRepresentation)
            
            return .init(
                image: originalIcon,
                cleanUp: cleanUp
            )
        } catch {
            cleanUp()
            throw error
        }
    }
}
