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
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        return try view.bitmapImage()
    }
}

private final class NoInsetHostingView<V: View>: NSHostingView<V> {
    override var safeAreaInsets: NSEdgeInsets { .init() }
}

private extension NSView {
    func bitmapImage() throws -> NSImage {
        let imageRep = try bitmapImageRepForCachingDisplay(in: bounds)
            .unwrapOrThrow("Could not make bitmapImageRep")
        
        cacheDisplay(in: bounds, to: imageRep)
        let cgImage = try imageRep.cgImage
            .unwrapOrThrow("Could not make cgImage")
        
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}
