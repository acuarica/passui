import SwiftUI

struct StatusBar<Left: View, Right: View>: View {
    @ViewBuilder let left: () -> Left
    @ViewBuilder let right: () -> Right

    var body: some View {
        HStack(spacing: 8) {
            left()
            Spacer()
            right()
            Divider()
                .frame(height: 14)
                .padding(.leading, 6)
                .padding(.trailing, 6)
            Button("Quit", systemImage: "xmark.rectangle") {
                NSApplication.shared.terminate(nil)
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.indigo.opacity(0.4))
    }
}
