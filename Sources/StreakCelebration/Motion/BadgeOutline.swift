import Foundation

/// The badge's outline: a hexagon standing on a point, all six corners 120° and rounded, fitted to a rect.
///
/// `squash` and `extrude` turn it into the silhouette of the badge mid-spin: each half is narrowed by
/// `squash` (the face turning away) and pushed out sideways by `extrude` (the edge coming into view), so
/// the top and bottom points open into short flats the width of the edge.
enum BadgeOutline {
    /// Corner radius as a fraction of the width, measured from the badge artwork.
    static let cornerRadius = 0.1126

    /// The outline clockwise from the top, as a closed polygon.
    /// - Parameters:
    ///   - rect: The outline's bounding box when face-on. The flat sides touch its left and right, the
    ///     rounded points its top and bottom.
    ///   - radius: Corner radius in points.
    static func points(
        in rect: CGRect,
        radius: Double,
        squash: Double = 1,
        extrude: Double = 0,
        stepsPerCorner: Int = 8
    ) -> [CGPoint] {
        let radius = max(radius, 0)
        let midX = Double(rect.midX)
        let halfWidth = Double(rect.width) / 2
        // A rounded 120° corner sits this far inside its sharp point, along the corner's bisector.
        let tip = radius / sin(.pi / 3)
        let top = Double(rect.minY) - (tip - radius)
        let bottom = Double(rect.maxY) + (tip - radius)
        // The slanted sides run at 30° to the horizontal.
        let rise = halfWidth * tan(.pi / 6)

        // Sharp corners clockwise from the top, each with the direction its bisector points outwards.
        let corners: [(x: Double, y: Double, bisector: Double)] = [
            (midX, top, -90),
            (midX + halfWidth, top + rise, -30),
            (midX + halfWidth, bottom - rise, 30),
            (midX, bottom, 90),
            (midX - halfWidth, bottom - rise, 150),
            (midX - halfWidth, top + rise, 210),
        ]

        func arc(_ index: Int, from start: Double, to end: Double, steps: Int) -> [(x: Double, y: Double)] {
            let corner = corners[index]
            let bisector = corner.bisector * .pi / 180
            let centreX = corner.x - tip * cos(bisector)
            let centreY = corner.y - tip * sin(bisector)
            return (0...steps).map { step in
                let angle = (start + (end - start) * Double(step) / Double(steps)) * .pi / 180
                return (centreX + radius * cos(angle), centreY + radius * sin(angle))
            }
        }

        let half = max(stepsPerCorner / 2, 1)
        let right = arc(0, from: -90, to: -60, steps: half)
            + arc(1, from: -60, to: 0, steps: stepsPerCorner)
            + arc(2, from: 0, to: 60, steps: stepsPerCorner)
            + arc(3, from: 60, to: 90, steps: half)
        let left = arc(3, from: 90, to: 120, steps: half)
            + arc(4, from: 120, to: 180, steps: stepsPerCorner)
            + arc(5, from: 180, to: 240, steps: stepsPerCorner)
            + arc(0, from: 240, to: 270, steps: half)

        // Each half goes out to its own side, including the top and bottom points they share.
        return right.map { CGPoint(x: midX + abs($0.x - midX) * squash + extrude, y: $0.y) }
            + left.map { CGPoint(x: midX - abs($0.x - midX) * squash - extrude, y: $0.y) }
    }
}
