import SwiftUI

/// A chunky flame with a small tongue on the left and the main tip leaning right, drawn in its rect.
struct FlameShape: Shape {
    /// -1...1. Leans the tips sideways; the bottom stays planted.
    var sway: Double = 0

    func path(in rect: CGRect) -> Path {
        let lean = sway * 0.035
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(
                x: Double(rect.minX) + (x + lean * (1 - y)) * Double(rect.width),
                y: Double(rect.minY) + y * Double(rect.height)
            )
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

/// A star with concave sides: four points for a sparkle, eight for the burst cut-out.
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

/// Soft wedges radiating from the centre, used as a slow-turning backdrop behind the lit flame.
struct SunburstShape: Shape {
    var rays = 14

    func path(in rect: CGRect) -> Path {
        let centerX = Double(rect.midX)
        let centerY = Double(rect.midY)
        let radius = Double(max(rect.width, rect.height)) / 2
        let step = 2 * Double.pi / Double(rays)
        let halfWidth = step * 0.22
        func point(_ angle: Double) -> CGPoint {
            CGPoint(x: centerX + cos(angle) * radius, y: centerY + sin(angle) * radius)
        }

        var path = Path()
        for i in 0..<rays {
            let angle = Double(i) * step
            path.move(to: CGPoint(x: centerX, y: centerY))
            path.addLine(to: point(angle - halfWidth))
            path.addLine(to: point(angle + halfWidth))
            path.closeSubpath()
        }
        return path
    }
}

/// The flame glyph with its inner drop, lit or dormant.
struct FlameView: View {
    enum Style {
        case lit
        case dormant
    }

    var style: Style
    var sway: Double = 0
    var size: CGSize
    var palette: StreakPalette

    var body: some View {
        let flame = FlameShape(sway: sway)
        let drop = DropShape()
        ZStack {
            // A round-joined stroke in the same fill softens the tips without redrawing the curve.
            flame.fill(bodyFill)
            flame.stroke(bodyFill, style: StrokeStyle(lineWidth: size.width * 0.07, lineJoin: .round))
            ZStack {
                drop.fill(coreFill)
                drop.stroke(coreFill, style: StrokeStyle(lineWidth: size.width * 0.03, lineJoin: .round))
            }
            .frame(width: size.width * 0.38, height: size.height * 0.44)
            .position(x: size.width * (0.5 + sway * 0.012), y: size.height * 0.70)
        }
        .frame(width: size.width, height: size.height)
    }

    private var bodyFill: LinearGradient {
        switch style {
        case .lit: LinearGradient(colors: palette.flame, startPoint: .top, endPoint: .bottom)
        case .dormant: LinearGradient(colors: palette.dormant, startPoint: .top, endPoint: .bottom)
        }
    }

    private var coreFill: LinearGradient {
        switch style {
        case .lit: LinearGradient(colors: palette.flameCore, startPoint: .top, endPoint: .bottom)
        case .dormant: LinearGradient(colors: [palette.dormantCore, palette.dormantCore], startPoint: .top, endPoint: .bottom)
        }
    }
}
