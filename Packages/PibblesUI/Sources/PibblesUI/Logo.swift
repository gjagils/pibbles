import SwiftUI

/// The Pibbles mark: four rounded shapes in a 2×2 arrangement with a brush ring,
/// drawn with shapes so it looks the same on iOS and Android.
public struct PibblesLogo: View {
    let size: Double

    public init(size: Double = 56.0) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(PibblesStyle.plum)
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: size * 0.04)
                .frame(width: size * 0.78, height: size * 0.78)
            VStack(spacing: size * 0.05) {
                HStack(spacing: size * 0.05) {
                    leaf(Color(red: 0.95, green: 0.89, blue: 0.81))
                    leaf(PibblesStyle.orange)
                }
                HStack(spacing: size * 0.05) {
                    leaf(PibblesStyle.teal)
                    leaf(PibblesStyle.orange)
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func leaf(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: size * 0.09)
            .fill(color)
            .frame(width: size * 0.22, height: size * 0.22)
    }
}
