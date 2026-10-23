import SwiftUI

/// A chunky flame with a small tongue on the left and the main tip leaning right, drawn in its rect.
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: Double(rect.minX) + x * Double(rect.width), y: Double(rect.minY) + y * Double(rect.height))
        }

        var path = Path()
        path.move(to: point(0.50, 1.00))
        path.addCurve(to: point(0.06, 0.60), control1: point(0.24, 1.00), control2: point(0.06, 0.82))
        path.addCurve(to: point(0.21, 0.21), control1: point(0.06, 0.44), control2: point(0.12, 0.31))
        path.addCurve(to: point(0.43, 0.36), control1: point(0.29, 0.27), control2: point(0.37, 0.35))
        path.addCurve(to: point(0.60, 0.00), control1: point(0.46, 0.21), control2: point(0.50, 0.07))
        path.addCurve(to: point(0.94, 0.60), control1: point(0.80, 0.10), control2: point(0.94, 0.33))
        path.addCurve(to: point(0.50, 1.00), control1: point(0.94, 0.83), control2: point(0.76, 1.00))
        path.closeSubpath()
        return path
    }
}

/// The token's outline, the flame from `FlameOutline`, fitted to its rect.
///
/// `squash` and `extrude` turn it into the silhouette of the spinning solid: the outline is narrowed by
/// `squash` (the face turning away) and pushed out on both sides by `extrude` (the edge coming into view).
struct TokenShape: InsettableShape {
    var squash = 1.0
    var extrude = 0.0
    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        let frame = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let minX = Double(frame.minX)
        let minY = Double(frame.minY)
        let width = Double(frame.width)
        let height = Double(frame.height)
        let midX = Double(frame.midX)

        var path = Path()
        for (index, unit) in FlameOutline.points.enumerated() {
            let x = minX + unit.x * width
            let y = minY + unit.y * height
            let offset = x - midX
            let side: Double = offset < 0 ? -1 : 1
            let point = CGPoint(x: midX + side * (abs(offset) * squash + extrude), y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> TokenShape {
        var copy = self
        copy.insetAmount += Double(amount)
        return copy
    }
}
