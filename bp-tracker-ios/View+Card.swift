import SwiftUI

// Reusable modifier for card styling
struct CardModifier: ViewModifier {
    var backgroundColor: Color = Color(UIColor.secondarySystemBackground)
    var cornerRadius: CGFloat = 10
    var shadowColor: Color = .gray
    var shadowRadius: CGFloat = 3
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor.opacity(0.4), radius: shadowRadius, x: shadowX, y: shadowY)
    }
}

// Extension to make applying the modifier easier
extension View {
    func cardStyle(backgroundColor: Color = Color(UIColor.secondarySystemBackground),
                   cornerRadius: CGFloat = 10,
                   shadowColor: Color = .gray,
                   shadowRadius: CGFloat = 3,
                   shadowX: CGFloat = 0,
                   shadowY: CGFloat = 2) -> some View {
        self.modifier(CardModifier(backgroundColor: backgroundColor,
                                   cornerRadius: cornerRadius,
                                   shadowColor: shadowColor,
                                   shadowRadius: shadowRadius,
                                   shadowX: shadowX,
                                   shadowY: shadowY))
    }
}
