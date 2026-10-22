import SwiftUI

/// A capsule button that gives slightly under the finger.
struct PillButtonStyle<Fill: ShapeStyle>: ButtonStyle {
    var fill: Fill
    var labelColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, weight: .semibold))
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(fill))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
