import SwiftUI

/// The Pibbles icon (docs/brand/pibbles-icon-origineel.png), as an image in the package.
public struct PibblesLogo: View {
    let size: Double

    public init(size: Double = 56.0) {
        self.size = size
    }

    public var body: some View {
        Image("Logo", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}
