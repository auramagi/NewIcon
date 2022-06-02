import SwiftUI
import TemplateSupport

/// Apply of the several supported colors as the new hue for the image
struct NewHue: IconTemplate, PreviewProvider {
    let icon: NSImage
    
    // Content can be any Decodable type
    let content: HueColor
    
    enum HueColor: String, Decodable {
        case red, orange, yellow, green, mint,
             teal, cyan, blue, indigo, purple,
             pink, black
    }
    
    // This function is needed to provide previews while using
    // a custom `Decodable` type for `content`
    static func makePreview(image: NSImage) -> NewHue {
        .init(icon: image, content: .mint) // minty green previews 🌱✨
    }
    
    // Expect size to be 1024x1024
    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .scaledToFit()
            .hue(content.color)
    }
}

extension NewHue.HueColor {
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .black: return .black
        }
    }
}

extension View {
    /// Hue change modifier that works around blendMode weirdness when used together with drawingGroup
    @ViewBuilder public func hue(_ color: Color) -> some View {
        Color(white: 0)
            .overlay(self)
            .overlay(
                color
                    .blendMode(.hue)
            )
            .drawingGroup()
            .mask(self)
    }
}


