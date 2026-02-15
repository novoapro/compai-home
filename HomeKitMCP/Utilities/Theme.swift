import SwiftUI

struct Theme {
    // MARK: - Colors
    
    struct Text {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(uiColor: .tertiaryLabel)
    }
    
    struct Tint {
        static let main = Color.orange // Modern primary color
        static let secondary = Color.teal
    }
    
    struct Status {
        static let active = Color.green
        static let inactive = Color.gray
        static let error = Color.red
        static let warning = Color.orange
    }
    
    // MARK: - Layout
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
}

// Extension to support custom colors without Asset Catalog
extension Theme {
    static var mainBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }
    
    static var contentBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }
    
    static var detailBackground: Color {
        Color(UIColor.tertiarySystemGroupedBackground)
    }
}
