import SwiftUI

/// https://blog.rampatra.com/adding-tooltips-to-swiftui-views-on-macos
private struct Tooltip<TooltipContent: View>: ViewModifier {
    @State private var isHovering = false
    let tooltipContent: TooltipContent

    init(@ViewBuilder content: () -> TooltipContent) {
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
    func tooltip(_ content: String) -> some View {
        self.modifier(Tooltip(content: { Text(content) }))
    }
}
