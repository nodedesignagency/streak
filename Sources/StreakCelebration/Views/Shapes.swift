import SwiftUI

/// The badge's outline: a rounded hexagon standing on a point, fitted to its rect (`Motion/BadgeOutline.swift`).
///
/// `squash` and `extrude` turn it into the silhouette of the spinning badge: each half is narrowed by
/// `squash` (the face turning away) and pushed out sideways by `extrude` (the edge coming into view), so the
/// points at the top and bottom open into short flats as the edge shows.
struct BadgeShape: InsettableShape {
    var squash = 1.0
    var extrude = 0.0
    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        let radius = BadgeOutline.cornerRadius * Double(rect.width) - insetAmount
        let points = BadgeOutline.points(
            in: rect.insetBy(dx: insetAmount, dy: insetAmount),
            radius: radius,
            squash: squash,
            extrude: extrude
        )
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    /// Insets keep the corners concentric, so an inset outline runs parallel to the edge (as long as the
    /// inset is smaller than the corner radius).
    func inset(by amount: CGFloat) -> BadgeShape {
        var copy = self
        copy.insetAmount += Double(amount)
        return copy
    }
}

/// The screen's rounded edge, drawn in from the middle of the bottom, up both sides at once, to the middle
/// of the top, as far as `progress` (0 nothing, 1 the whole edge).
struct ScreenEdgeReveal: Shape {
    var progress: Double
    var cornerRadius: Double

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, Double(rect.width) / 2, Double(rect.height) / 2)
        // The right half, bottom to top; the left half is its mirror image.
        var half = Path()
        half.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        half.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.minY),
            radius: radius
        )
        half.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
            tangent2End: CGPoint(x: rect.midX, y: rect.minY),
            radius: radius
        )
        half.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        let drawn = half.trimmedPath(from: 0, to: min(max(progress, 0), 1))
        // One path for both halves, so where they meet they are stroked once, not twice.
        var path = drawn
        path.addPath(drawn, transform: CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * rect.midX, ty: 0))
        return path
    }
}
