import SwiftUI

struct Readme: View {
    let readmeURL: URL
    let content: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                Text(LocalizedStringKey(content))
                    .textSelection(.enabled)
            }
            Label(readmeURL.lastPathComponent, systemImage: "book")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.2))
                )
                .tooltip(readmeURL.path)
        }
    }
}
