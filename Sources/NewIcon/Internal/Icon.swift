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
    let target: URL
    
    let image: NSImage
    
    let cleanUp: () -> Void
    
    static let workspace: NSWorkspace = .shared
    
    func replace(with newImage: NSImage) {
        Self.workspace.setIcon(newImage, forFile: target.path)
    }
    
    func apply(_ renderedTemplate: AnyView, to output: URL?) throws {
        let newImage = try renderedTemplate
            .frame(width: 1024, height: 1024)
            .colorScheme(.light)
            .asNSImage()
        
        if let output = output {
            try newImage.write(to: output)
        } else {
            replace(with: newImage)
        }
    }
}

extension Icon {
    static func load(target: URL, imageURL: URL?) throws -> Icon {
        if let imageURL = imageURL {
            return try .provided(in: imageURL, target: target)
        } else {
            return try .extracted(from: target)
        }
    }
    
    static func provided(in fileURL: URL, target: URL) throws -> Self {
        let image = try NSImage(contentsOf: fileURL)
            .unwrapOrThrow("Could not load image at \(fileURL.path)")
        
        return .init(
            target: target,
            image: image,
            cleanUp: { }
        )
    }
    
    static func extracted(from target: URL) throws -> Self {
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
                target: target,
                image: originalIcon,
                cleanUp: cleanUp
            )
        } catch {
            cleanUp()
            throw error
        }
    }
}
