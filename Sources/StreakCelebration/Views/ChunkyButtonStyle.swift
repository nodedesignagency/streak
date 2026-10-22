import SwiftUI

/// A tactile button with a darker bottom edge that the face presses down into.
struct ChunkyButtonStyle<Face: ShapeStyle>: ButtonStyle {
    var face: Face
    var labelColor: Color
    var cornerRadius = 16.0
    var depth = 4.0

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return configuration.label
            .font(.system(.headline, design: .rounded, weight: .heavy))
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(shape.fill(face))
            .offset(y: configuration.isPressed ? depth : 0)
            .background {
                shape
                    .fill(face)
                    .overlay(shape.fill(.black.opacity(0.22)))
                    .offset(y: depth)
            }
            .padding(.bottom, depth)
            .contentShape(shape)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
