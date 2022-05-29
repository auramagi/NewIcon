//
//  View+.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import AppKit
import SwiftUI

extension View {
    func asNSImage() throws -> NSImage {
        let controller = NSHostingController(rootView: self)
        let window = SnapshottingWindow()
        window.backingType = .buffered
        window.styleMask = [.borderless, .fullSizeContentView]
        window.colorSpace = .deviceRGB
        window.contentViewController = controller
        return try controller.view.bitmapImage()
    }
}

extension NSView {
    func bitmapImage() throws -> NSImage {
        let imageRep = try bitmapImageRepForCachingDisplay(in: bounds)
            .unwrapOrThrow("Could not make bitmapImageRep")
        
        cacheDisplay(in: bounds, to: imageRep)
        let cgImage = try imageRep.cgImage
            .unwrapOrThrow("Could not make cgImage")
        
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}

private class SnapshottingWindow: NSWindow {
    override var backingScaleFactor: CGFloat { 1 }
}
