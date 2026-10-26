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
