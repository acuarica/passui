import SwiftUI

/// https://blog.rampatra.com/adding-tooltips-to-swiftui-views-on-macos
private struct Tooltip<TTContent: View>: ViewModifier {
    @State private var isHovering = false
    let tooltipContent: TTContent

    init(@ViewBuilder content: () -> TTContent) {
        self.tooltipContent = content()
    }

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
            }
            .popover(isPresented: $isHovering) {
                tooltipContent
                    .padding(10)
                    .background(
                        Color.blue.opacity(0.1)
                    )
            }
    }
}

extension View {
    // func tooltip<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    //     self.modifier(Tooltip(content: content))
    // }

    func tooltip(_ content: String) -> some View {
        self.modifier(Tooltip(content: { Text(content) }))
    }
}
