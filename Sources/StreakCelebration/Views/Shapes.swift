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

/// A star with concave sides, used for glints.
struct SparkleShape: Shape {
    var points = 4
    /// Radius of the valleys between points, relative to the outer radius.
    var pinch = 0.2

    func path(in rect: CGRect) -> Path {
        let centerX = Double(rect.midX)
        let centerY = Double(rect.midY)
        let radius = Double(min(rect.width, rect.height)) / 2
        let step = 2 * Double.pi / Double(points)
        func point(_ angle: Double, _ distance: Double) -> CGPoint {
            CGPoint(x: centerX + cos(angle) * distance, y: centerY + sin(angle) * distance)
        }

        var path = Path()
        path.move(to: point(-.pi / 2, radius))
        for i in 0..<points {
            let angle = -Double.pi / 2 + Double(i) * step
            path.addQuadCurve(to: point(angle + step, radius), control: point(angle + step / 2, radius * pinch))
        }
        path.closeSubpath()
        return path
    }
}

/// A wavy-edged seal, like a minted medal, with a lobe at twelve o'clock.
struct RosetteShape: Shape {
    var lobes = 14
    /// How deep the waves cut in, relative to the radius.
    var depth = 0.055

    func path(in rect: CGRect) -> Path {
        let centerX = Double(rect.midX)
        let centerY = Double(rect.midY)
        let radius = Double(min(rect.width, rect.height)) / 2
        let steps = lobes * 24

        var path = Path()
        for step in 0...steps {
            let turn = Double(step) / Double(steps) * 2 * .pi
            let wave = cos(turn * Double(lobes) / 2)
            let distance = radius * (1 - depth + depth * wave * wave)
            let point = CGPoint(
                x: centerX + cos(turn - .pi / 2) * distance,
                y: centerY + sin(turn - .pi / 2) * distance
            )
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
