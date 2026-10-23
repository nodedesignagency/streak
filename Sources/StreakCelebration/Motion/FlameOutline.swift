import Foundation

/// The token's silhouette: a flame with a tall centre tongue and two side tongues curling in.
///
/// It is symmetric on purpose. The token spins, and from behind you see its outline mirrored, so an
/// asymmetric flame would look wrong whenever the back comes round.
enum FlameOutline {
    typealias Point = (x: Double, y: Double)

    /// The right half as cubic Béziers, from the bottom centre up to the top tip, in a unit square
    /// with y growing downwards.
    private static let rightHalf: [(start: Point, control1: Point, control2: Point, end: Point)] = [
        ((0.50, 1.00), (0.80, 1.00), (0.98, 0.86), (0.96, 0.64)), // round belly
        ((0.96, 0.64), (0.95, 0.44), (0.99, 0.30), (0.86, 0.17)), // side tongue, curling in at the tip
        ((0.86, 0.17), (0.86, 0.29), (0.77, 0.36), (0.70, 0.41)), // down into the valley
        ((0.70, 0.41), (0.71, 0.25), (0.63, 0.09), (0.50, 0.00)), // up the centre tongue
    ]

    /// The whole outline, clockwise from the bottom centre, as points in a unit square.
    static let points: [Point] = {
        let right = rightHalf.flatMap { segment in
            (0...20).map { step -> Point in
                let t = Double(step) / 20
                let u = 1 - t
                let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                return (
                    x: a * segment.start.x + b * segment.control1.x + c * segment.control2.x + d * segment.end.x,
                    y: a * segment.start.y + b * segment.control1.y + c * segment.control2.y + d * segment.end.y
                )
            }
        }
        let left = right.reversed().map { (x: 1 - $0.x, y: $0.y) }
        return right + left
    }()
}
