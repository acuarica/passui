import SwiftUI

struct Markdown: View {
    let content: String
    let fileName: String
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(LocalizedStringKey(content)).lineLimit(10)
            Label(fileName, systemImage: "book")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.2))
                )
        }
    }
}
