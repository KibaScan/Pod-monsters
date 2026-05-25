import SwiftUI

public struct FactionButtonStyle: ButtonStyle {
    public let colors: [Color]
    public let shadowColor: Color
    
    public init(colors: [Color], shadowColor: Color) {
        self.colors = colors
        self.shadowColor = shadowColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(Capsule())
            .shadow(color: shadowColor.opacity(0.3), radius: 5, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(.bouncy), value: configuration.isPressed)
    }
}
