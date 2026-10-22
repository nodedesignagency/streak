import SwiftUI

/// A faint grid of dots that fades out from just above the centre, giving the dark stage some texture.
struct DotGrid: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            let spacing = 18.0
            let width = Double(size.width)
            let height = Double(size.height)
            let centerX = width / 2
            let centerY = height * 0.36
            let reach = max(width, height) * 0.6

            var y = spacing / 2
            while y < height {
                var x = spacing / 2
                while x < width {
                    let fade = 1 - ((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY)).squareRoot() / reach
                    if fade > 0 {
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                            with: .color(color.opacity(fade))
                        )
                    }
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
