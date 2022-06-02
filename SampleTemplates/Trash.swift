import SwiftUI
import TemplateSupport

/// Make grayscale and overlay a red trash icon.
struct Trash: IconTemplate, PreviewProvider {
    let icon: NSImage

    // Mark this template as not needing any additional content
    typealias Content = Never

    // Expect size to be 1024x1024
    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .scaledToFit()
            .grayscale(1)
            .overlay(alignment: .center) {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .symbolVariant(.circle.fill)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.red)
                    .frame(width: 384, height: 384)
            }
    }
}
