import SwiftUI

// Shared with the widget extension, so it must not depend on app-only types.
extension Color {
    /// The deep navy behind the Hanuman artwork.
    static let night = Color(red: 0.055, green: 0.090, blue: 0.170)
    static let saffron = Color(red: 0.96, green: 0.52, blue: 0.16)
    static let marigold = Color(red: 1.0, green: 0.76, blue: 0.30)
    /// Deep enough for white text in both appearances.
    static let ember = Color(red: 0.72, green: 0.22, blue: 0.07)
}

extension ShapeStyle where Self == LinearGradient {
    static var saffronGlow: LinearGradient {
        LinearGradient(colors: [.marigold, .saffron, Color("AccentColor")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var emberGlow: LinearGradient {
        LinearGradient(colors: [Color(red: 0.90, green: 0.40, blue: 0.10), .ember], startPoint: .leading, endPoint: .trailing)
    }
}
