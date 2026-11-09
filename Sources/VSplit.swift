import AppKit
import SwiftUI

struct VSplit<TopContent: View, BottomContent: View>: NSViewControllerRepresentable {
    let topContent: TopContent
    let bottomContent: BottomContent

    init(
        @ViewBuilder top: () -> TopContent,
        @ViewBuilder bottom: () -> BottomContent
    ) {
        self.topContent = top()
        self.bottomContent = bottom()
    }

    func makeNSViewController(context: Context) -> NSSplitViewController {
        let controller = NSSplitViewController()
        controller.splitView.isVertical = false
        controller.splitView.dividerStyle = .thick

        controller.addSplitViewItem(
            NSSplitViewItem(viewController: NSHostingController(rootView: topContent)))
        controller.addSplitViewItem(
            NSSplitViewItem(viewController: NSHostingController(rootView: bottomContent)))
        return controller
    }

    func updateNSViewController(_ controller: NSSplitViewController, context: Context) {
        (controller.splitViewItems[0].viewController as? NSHostingController<TopContent>)?
            .rootView = topContent
        (controller.splitViewItems[1].viewController as? NSHostingController<BottomContent>)?
            .rootView = bottomContent
    }
}
