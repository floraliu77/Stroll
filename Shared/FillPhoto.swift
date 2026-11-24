import SwiftUI

/// A photo that fills the available width and a fixed height, cropped to fit.
///
/// Use this instead of `Image.resizable().scaledToFill().frame(maxWidth: .infinity)`: with that,
/// a very wide photo (Flagstaff Hill's panorama is 4.6 times wider than tall) makes the box, and
/// all the text laid out next to it, wider than the screen, so lines get cut off. Here the box
/// takes its size from the space around it, and the photo only fills it.
struct FillPhoto: View {
    let name: String
    let height: CGFloat

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay { Image(name).resizable().scaledToFill() }
            .clipped()
    }
}
