import SwiftUI

/// https://blog.rampatra.com/adding-tooltips-to-swiftui-views-on-macos
private struct Tooltip<TTContent: View>: ViewModifier {
    @State private var isHovering = false
    let tooltipContent: TTContent

    init(@ViewBuilder content: () -> TTContent) {
        self.tooltipContent = content()
    }

    /// Fix before using it
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .overlay(alignment: .top) {
                if isHovering {
                    tooltipContent
                        .fixedSize()
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.windowBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2))
                        )
                        .shadow(radius: 3)
                        .offset(y: -40)
                        .transition(.opacity.combined(with: .scale))
                }
            }
    }
}

extension View {
    func tooltip<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        self.modifier(Tooltip(content: content))
    }

    func tooltip(_ content: String) -> some View {
        self.help(content)
    }
}
