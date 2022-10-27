import Foundation

public enum NewIcon { }

public extension NewIcon {
    enum IconSource {
        case fileIcon(URL)

        case imageFile(URL)
    }
    
    enum Output {
        case fileIcon(URL)

        case imageFile(URL)
    }
}
