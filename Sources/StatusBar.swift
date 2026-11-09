import SwiftUI

struct StatusBar: View {
    let left: String
    let right: String

    var body: some View {
        HStack(spacing: 8) {
            Text(left)
            Spacer()
            Text(right)
            Divider()
                .frame(height: 14)
                .padding(.leading, 6)
                .padding(.trailing, 6)
            Button("Quit", systemImage: "xmark.rectangle") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.caption2)
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.indigo.opacity(0.4))
    }
}
