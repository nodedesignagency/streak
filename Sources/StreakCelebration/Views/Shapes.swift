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

/// A teardrop with its tip at the top.
struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: Double(rect.minX) + x * Double(rect.width), y: Double(rect.minY) + y * Double(rect.height))
        }

        var path = Path()
        path.move(to: point(0.5, 0))
        path.addCurve(to: point(0, 0.66), control1: point(0.32, 0.22), control2: point(0, 0.40))
        path.addCurve(to: point(0.5, 1), control1: point(0, 0.86), control2: point(0.22, 1))
        path.addCurve(to: point(1, 0.66), control1: point(0.78, 1), control2: point(1, 0.86))
        path.addCurve(to: point(0.5, 0), control1: point(1, 0.40), control2: point(0.68, 0.22))
        path.closeSubpath()
        return path
    }
}

/// The coin's outline: a circle fitted to its rect.
///
/// `squash` and `extrude` turn it into the silhouette of the spinning coin: the circle is narrowed by
/// `squash` (the face turning away) and pushed out on both sides by `extrude` (the milled edge coming
/// into view), which gives the flat-sided lozenge a thick coin shows mid-turn.
struct TokenShape: InsettableShape {
    var squash = 1.0
    var extrude = 0.0
    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        let frame = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let midX = Double(frame.midX)
        let midY = Double(frame.midY)
        let radiusX = Double(frame.width) / 2
        let radiusY = Double(frame.height) / 2
        let steps = 120

        var path = Path()
        for index in 0...steps {
            let angle = Double(index) / Double(steps) * 2 * .pi
            let x = midX + cos(angle) * radiusX
            let y = midY + sin(angle) * radiusY
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
