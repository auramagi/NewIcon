//
//  NSImage+.swift
//  
//
//  Created by Mikhail Apurin on 10.05.2022.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

extension NSImage {
    func write(to url: URL) throws {
        let cgImage = try cgImage(forProposedRect: nil, context: nil, hints: nil)
            .unwrapOrThrow("Could not convert to CGImage")
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        bitmap.size = size
        let fileType = NSBitmapImageRep.FileType.from(url: url)
        try bitmap.representation(using: fileType, properties: [:])
            .unwrapOrThrow("Could not make \(fileType) representation")
            .write(to: url, options: .atomic)
    }
}
extension NSBitmapImageRep.FileType {
    static func from(url: URL) -> Self {
        switch url.pathExtension.lowercased() {
        case "tiff":
            return .tiff
            
        case "bmp":
            return .bmp
            
        case "gif":
            return .gif
            
        case "jpeg", "jpg":
            return .jpeg
            
        case "png":
            return .png
            
        default:
            return .png
        }
    }
}
