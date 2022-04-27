//
//  TextCommand.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import AppKit
import ArgumentParser
import Foundation
import SwiftUI

struct TextCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Overlay text over the original icon."
    )
    
    @Argument(
        help: "Path to the file or directory.",
        completion: .file()
    )
    var path: String
    
    @Argument(
        help: "Text to overlay."
    )
    var text: String
    
    
    func run() throws {        
        guard FileManager.default.fileExists(atPath: path) else {
            throw "File does not exist"
        }

        let workspace = NSWorkspace.shared
        
        let oldIcon = workspace.icon(forFile: path)
        
        workspace.setIcon(nil, forFile: path)
        let originalIcon = workspace.icon(forFile: path)
        
        do {
            try setNewIcon(originalIcon: originalIcon, workspace: workspace)
        } catch {
            workspace.setIcon(oldIcon, forFile: path)
            throw error
        }
    }
    
    private func setNewIcon(originalIcon: NSImage, workspace: NSWorkspace) throws {
        let bestRepresentation = try originalIcon.bestRepresentation(for: .infinite, context: nil, hints: [:])
            .unwrapOrThrow("Could not convert the original icon")
        
        let originalIcon = NSImage()
        originalIcon.addRepresentation(bestRepresentation)
        
        let newIcon = try IconTextView(icon: originalIcon, text: text).asNSImage()
        
        workspace.setIcon(newIcon, forFile: path)
    }
}

private struct IconTextView: View {
    let icon: NSImage
    
    let text: String
    
    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .frame(width: 1024, height: 1024)
            .overlay(
                Text(text)
                    .font(.system(size: 160, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.1)
                    .multilineTextAlignment(.center)
                    .frame(width: 612)
                    .frame(maxHeight: 189)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.black.opacity(0.56))
                    )
                    .alignmentGuide(VerticalAlignment.center) { $0.height / 2 - 184 }
            )
    }
}
