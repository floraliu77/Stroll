import SwiftUI

/// Colours from the Figma file "AxD-Stroll" (the "Stroll" variable collection).
extension Color {
    static let strollGreen = Color(hex: 0x2F6B4F)      // brand/green
    static let strollPaper = Color(hex: 0xF6F3EA)      // bg/paper
    static let strollInk = Color(hex: 0x1B2420)        // text/ink
    static let strollMuted = Color(hex: 0x5B6A63)      // text/muted
    static let strollBorder = Color(hex: 0xE3DDD0)     // border/subtle
    static let strollAmber = Color(hex: 0xF2B84B)      // brand/amber (walk progress)
    static let strollNight = Color(hex: 0x0F1714)      // brand/night (walk progress card)

    /// category/* colours, keyed by StrollContent.Category.id. From the ethical audit: each passes
    /// WCAG AA (4.5:1) on paper and white, and the four stay apart with color blindness
    /// (orange, purple and navy from MJ's audit; a brighter green so it isn't confused with navy).
    static func category(_ id: String) -> Color {
        switch id {
        case "architecture": return Color(hex: 0xA15C17)
        case "natural-history": return Color(hex: 0x007949)
        case "public-art": return Color(hex: 0x8A4FB0)
        case "history": return Color(hex: 0x1E4167)
        default: return .strollGreen
        }
    }

    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
