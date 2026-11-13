import SwiftUI

/// Colours from the Figma file "AxD-Stroll" (the "Stroll" variable collection).
extension Color {
    static let strollGreen = Color(hex: 0x2F6B4F)      // brand/green
    static let strollPaper = Color(hex: 0xF6F3EA)      // bg/paper
    static let strollInk = Color(hex: 0x1B2420)        // text/ink
    static let strollMuted = Color(hex: 0x5B6A63)      // text/muted
    static let strollBorder = Color(hex: 0xE3DDD0)     // border/subtle

    /// category/* colours, keyed by StrollContent.Category.id.
    static func category(_ id: String) -> Color {
        switch id {
        case "architecture": return Color(hex: 0xB5652B)
        case "natural-history": return Color(hex: 0x3F7D4F)
        case "public-art": return Color(hex: 0x7A55A6)
        case "history": return Color(hex: 0x2E6A8E)
        default: return .strollGreen
        }
    }

    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
